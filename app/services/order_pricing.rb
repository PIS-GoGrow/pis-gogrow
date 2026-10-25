# frozen_string_literal: true

# Calcula cuánto paga el empleado por cada ítem de un pedido y qué beneficios
# cubren cada vianda.
#
# Se intenta aplicar beneficios con prioridad a las viandas más caras, con un máximo
# de 100% de beneficio en cada vianda. Además, si el usuario tiene muchos beneficios,
# se consumen beneficios solo hasta llegar al 100% por vianda. Se aplican primero
# beneficios de porcentaje más alto.
#
# Con modifiable_order (al modificar una orden) se le devuelve a cada beneficio lo que
# esa orden ya tenía reservado, para no rechazarla contra su propio consumo.
class OrderPricing
  # benefits es un hash de la forma:
  #   { benefit, units_used }
  OrderItemPricing = Data.define(:price, :discounted_price, :benefits)
  # total contiene el porcentaje total de subsidios aplicable, base el porcentaje de
  # subsidio mensual, y specials es un arreglo de hashes de la forma
  #   { name:, percentage: }
  # que contiene los beneficios no mensuales.
  Summary = Data.define(:total, :base, :specials)

  attr_reader :consumer

  # Si queremos modificar una orden, modifiable_order representa la orden que estamos
  # modificando. Esa orden está sujeta a cambios: podemos cambiar la cantidad de
  # beneficios que tiene asignada.
  def initialize(consumer, modifiable_order: nil)
    @consumer = consumer
    @modifiable_order = modifiable_order
  end

  # items: [{ schedule: { id:, date:, price: }, quantity: }].
  # Devuelve un hash:
  #   { schedule_id: OrderItemPricing }
  # donde OrderItemPricing contiene toda la información de beneficios necesaria:
  # - el precio base
  # - el valor que se descuenta
  # - un arreglo con los beneficios aplicados
  def call(items)
    # Los beneficios que tenemos disponible para usar.
    # De la forma { benefit: remaining_uses }
    benefit_left = benefits.to_h { |benefit| [ benefit, remaining_uses(benefit) ] }

    # Ordenamos los items según el precio por unidad del menú al que corresponden,
    # de mayor a menor.
    # De esta manera, si quedan pocos beneficios, estos se van a aplicar sobre las
    # órdenes más caras, beneficiando al consumidor.
    items.sort_by! { |item| item[:schedule].price }.reverse!

    items.to_h do |item|
      schedule = item[:schedule]
      quantity = item[:quantity]

      # coverage es un arreglo con cada beneficio que se va aplicar, su porcentaje y
      # la cantidad que se va a aplicar
      coverage = []

      # Calculamos para cada beneficio especial cuánto podemos aplicar a la orden
      benefits.each do |benefit|
        # No aplicar el beneficio si no es válido en la fecha dada
        next unless benefit.valid_on?(schedule.date)
        # No aplicar el beneficio si se supera el precio máximo
        next if benefit.max_price && benefit.max_price < quantity * schedule.price
        # No seguir aplicando beneficios si ya superamos el cien porciento con los que
        # tenemos en cada una de las unidades
        next if coverage.sum { |benefit| benefit[1] * benefit[2] } >= 100 * quantity

        appliable_units = [ quantity, benefit_left[benefit] ].compact.min

        next unless appliable_units.positive?

        benefit_left[benefit] -= appliable_units if benefit_left[benefit]
        coverage << [ benefit, benefit.percentage, appliable_units ]
      end

      [ schedule.id, pricing_for(schedule.price, quantity, coverage) ]
    end
  end

  # Devuelve los usos disponibles para un beneficio, teniendo en cuenta
  # que la orden modificable puede tenerlos.
  # nil significa usos ilimitados, como el de antigüedad.
  def remaining_uses(benefit)
    # Un beneficio vencido solo llega acá si la orden modificable ya lo usaba: conserva
    # lo que tenía, pero no cubre viandas nuevas.
    return benefit_held.fetch(benefit.id, 0) if benefit.expired?
    return if benefit.amount.nil?

    [ benefit.amount - benefit_used.fetch(benefit.id, 0) + benefit_held.fetch(benefit.id, 0), 0 ].max
  end

  # Lo que le corresponde hoy a una vianda que entre en todos los cupos: el base
  # y los especiales vigentes que todavía tienen usos. nil si no tiene ninguno.
  def summary(date: Date.current)
    base_percentage = @consumer.monthly_benefit_percentage
    specials = @consumer.special_benefits.select { it.valid_on?(date) && remaining_uses(it) != 0 }

    return if base_percentage.zero? && specials.empty?

    Summary.new(
      total: [ base_percentage + specials.sum(&:percentage), 100 ].min,
      base: base_percentage,
      specials: specials.map { { name: it.description.to_s, percentage: it.percentage } }
    )
  end

  private

  # Devuelve los beneficios no expirados del usuario ordenados por porcentaje,
  # de modo de que los beneficios de mayor porcentaje se apliquen antes.
  def benefits
    @benefits ||= consumer
      .benefits
      .where.not(status: :expired)
      .or(consumer.benefits.where(id: @modifiable_order&.order_benefits&.select(:benefit_id)))
      .order(percentage: :desc)
      .to_a
  end

  # Por vianda y no por ítem: cada vianda puede tener una combinación distinta
  # de beneficios según cuántos usos le quedaban a cada uno.
  def pricing_for(unit_price, quantity, coverage)
    # Para cada unidad, evaluamos qué beneficios se pueden aplicar a él y calculamos
    # su precio.
    # El precio descontado total, es la suma de los precios descontados de cada unidad
    discount_percentage = coverage.sum { |benefit| benefit[1] * benefit[2] } / quantity.to_f
    discounted_price = unit_price * quantity * (100 - discount_percentage.clamp(0, 100)) / 100

    benefits = coverage.filter_map do |benefit, _percentage, units_used|
      [ benefit, units_used ] if benefit && units_used.positive?
    end

    OrderItemPricing.new(
      price: unit_price * quantity,
      discounted_price: discounted_price.round(2),
      benefits: benefits.to_h
    )
  end

  def benefit_used
    @benefit_used ||= OrderBenefit
      .joins(:order)
      .where(benefit_id: benefits.map(&:id))
      .where.not(orders: { status: [ :cancelled, :rejected ] })
      .group(:benefit_id)
      .sum(:benefit_used)
  end

  # Indica para cada beneficio, cuánto se uso en la orden modificable
  def benefit_held
    return @benefit_held if @benefit_held

    if @modifiable_order
      @benefit_held =
        @modifiable_order
          .order_benefits
          .where(benefit_id: benefits.map(&:id))
          .group(:benefit_id)
          .sum(:benefit_used)
    else
      @benefit_held = {}
    end
  end
end
