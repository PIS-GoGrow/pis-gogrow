# frozen_string_literal: true

# Calcula cuánto paga el empleado por cada ítem de un pedido y qué beneficios
# cubren cada vianda. El subsidio base cubre las viandas que entran en el cupo
# mensual restante y cada subsidio especial, las que entran en sus usos
# restantes; los porcentajes de una misma vianda se suman con tope en 100%.
# Cada beneficio se reparte sobre las primeras viandas, en el orden de los ítems.
#
# Con modifiable_order (al modificar una orden) se le devuelve a cada beneficio lo que
# esa orden ya tenía reservado, para no rechazarla contra su propio consumo.
class OrderPricing
  Line = Data.define(:price, :discounted_price, :benefits)
  Summary = Data.define(:total, :base, :specials)

  attr_reader :consumer

  # Si queremos modificar una orden, modifiable_order representa la orden que estamos
  # modificando. Esa orden está sujeta a cambios: podemos cambiar
  def initialize(consumer, modifiable_order: nil)
    @consumer = consumer
    @modifiable_order = modifiable_order
  end

  # items: [{ schedule:, quantity: }].
  # Devuelve un Line por ítem, con benefits como { Benefit => viandas cubiertas }.
  def call(items)
    # Los beneficios que tenemos disponible para usar.
    # De la forma { benefit: remaining_uses }
    benefit_left = benefits.to_h { |benefit| [ benefit, remaining_uses(benefit) ] }

    # Ordenamos los items según el precio por unidad del menú al que corresponden,
    # de mayor a menor.
    # De esta manera, si quedan pocos beneficios, estos se van a aplicar sobre las
    # órdenes más caras, beneficiando al consumidor.
    items.sort_by! { |item| item[:schedule].menu.price }.reverse!
    
    items.to_h do |item|
      schedule = item[:schedule]
      quantity = item[:quantity]

      # coverage es un arreglo con cada beneficio que se va aplicar, su porcentaje y
      # la cantidad que se va a aplicar
      coverage = []

      # Calculamos para cada beneficio especial cuánto podemos aplicar a la orden
      benefits.each do |benefit|
        # No aplicar el beneficio
        next unless benefit.valid_on?(schedule.date)
        # No aplicar el beneficio si se supera el precio máximo
        next if benefit.max_price && benefit.max_price < quantity * schedule.menu.price
        # No seguir aplicando beneficios si ya superamos el cien porciento con los que
        # tenemos
        next if coverage.sum { |benefit| benefit[1] } >= 100

        appliable_units = [ quantity, benefit_left[benefit] ].compact.min
        benefit_left[benefit] -= appliable_units if benefit_left[benefit]
        coverage << [ benefit, benefit.percentage, appliable_units ]
      end

      [schedule.id, line_for(schedule.menu.price, quantity, coverage)]
    end
  end

  # Devuelve los usos disponibles para un beneficio, teniendo en cuenta
  # que la orden modificable puede tenerlos.
  # nil significa usos ilimitados, como el de antigüedad.
  def remaining_uses(benefit)
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
      .order(percentage: :asc)
      .to_a
  end

  # Por vianda y no por ítem: cada vianda puede tener una combinación distinta
  # de beneficios según cuántos usos le quedaban a cada uno.
  def line_for(unit_price, quantity, coverage)
    # Para cada unidad, evaluamos qué beneficios se pueden aplicar a él y calculamos
    # su precio.
    # El precio descontado total, es la suma de los precios descontados de cada unidad
    discounted_price = (0...quantity).sum do |unit|
      percentage = coverage.sum do |_benefit, benefit_percentage, units|
        unit < units ? benefit_percentage : 0
      end

      unit_price * (100 - percentage.clamp(0, 100)) / 100
    end

    Line.new(
      price: unit_price * quantity,
      discounted_price: discounted_price.round(2),
      benefits: coverage.filter_map { |benefit, _percentage, units| [ benefit, units ] if benefit && units.positive? }.to_h
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
