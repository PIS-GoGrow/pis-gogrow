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
class Orders::Pricing
  BenefitUsed = Data.define(:units_used, :discount)
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

  # items: [{ schedule: { id:, date:, price: }, quantity:, benefits: [id] }].
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

    items.map do |item|
      schedule = item[:schedule]
      selected_benefits = benefits_from_ids(item[:benefits].to_a)
      quantity = item[:quantity]

      # Para cada beneficio, cuántas unidades se usaron y cuánto descuento se aplicó
      benefit_used = selected_benefits.zip(Array.new(benefits.length, BenefitUsed[0, 0])).to_h

      coverage = Array.new(quantity) { [] } # indica qué beneficios se aplican para cada unidad
      pct_sum = Array.new(quantity, 0) # indica cuánto se descuenta para cada unidad

      # Calculamos para cada beneficio cuánto podemos aplicar a la orden
      selected_benefits.each do |benefit|
        # No aplicar el beneficio si no es válido en la fecha dada
        next unless benefit.valid_on?(schedule.date)
        # No aplicar el beneficio si se supera el precio máximo
        next if benefit.max_price && benefit.max_price < schedule.price

        # Para cada una de las unidades disponibles del beneficio, con límite en quantity,
        # seleccionamos la unidad del pedido a la que aplicársela.
        [ benefit_left[benefit] || quantity, quantity ].min.times do
          # Calculamos las unidades con:
          best = nil # mayor descuento con espacio disponible para este beneficio,
          low = nil  # menor descuento

          quantity.times do |unit|
            next if coverage[unit].include? benefit

            low = unit if low.nil? || pct_sum[unit] < pct_sum[low]
            if pct_sum[unit] + benefit.percentage <= 100 && (best.nil? || pct_sum[unit] > pct_sum[best])
              best = unit
            end
          end
          unit = best || low
          break if unit.nil? || pct_sum[unit] == 100

          benefit_used[benefit] = BenefitUsed[
            units_used: benefit_used[benefit].units_used + 1,
            discount: benefit_used[benefit].discount + [ benefit.percentage, 100 - pct_sum[unit] ].min / 100.0 * schedule.price
          ]
          pct_sum[unit] += benefit.percentage
          coverage[unit] << j
        end

        benefit_left[benefit] -= benefit_used[benefit].units_used if benefit_left[benefit]
      end

      benefit_used.select! { |_benefit, benefit_used| benefit_used.units_used > 0 }

      [ schedule.id, pricing_for(schedule.price, quantity, benefit_used, pct_sum) ]
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

  # Por vianda y no por ítem: cada vianda puede tener una combinación distinta
  # de beneficios según cuántos usos le quedaban a cada uno.
  def pricing_for(unit_price, quantity, benefit_used, pct_sum)
    # Para cada unidad, evaluamos qué beneficios se pueden aplicar a él y calculamos
    # su precio.
    # El precio descontado total es la suma de los precios descontados de cada unidad
    discount_percentage = pct_sum.map { |pct| pct.clamp(0, 100) }.sum / quantity.to_f
    discounted_price = unit_price * quantity * (100 - discount_percentage) / 100

    OrderItemPricing.new(
      price: unit_price * quantity,
      discounted_price: discounted_price.round(2),
      benefits: benefit_used
    )
  end

  # Devuelve los beneficios no expirados seleccionados por el usuario.
  # El orden es: primero los beneficios mensuales, después los que no tienen límite
  # y después el resto ordenado por porcentaje de mayor a menor.
  # El usuario solo puede seleccionar los beneficios del último grupo.
  def benefits_from_ids(benefit_ids)
    unlimited, limited = special_benefits .partition { |benefit| benefit.amount.nil? }

    monthly_benefits +
      unlimited +
      limited.select { |benefit| benefit_ids.include? benefit.id.to_i }
  end

  def benefits
    monthly_benefits + special_benefits
  end

  def loaded_benefits
    @loaded_benefits ||=
      consumer
        .benefits
        .includes(benefit_configuration: :benefit_rules)
        .where.not(status: :expired)
        .or(consumer.benefits.where(id: @modifiable_order&.order_benefits&.select(:benefit_id)))
        .order(percentage: :desc)
        .to_a
  end

  def monthly_benefits
    @monthly_benefits ||= loaded_benefits.select { |b| b.monthly? }
  end

  def special_benefits
    @special_benefits ||= loaded_benefits - monthly_benefits
  end

  def benefit_used
    @benefit_used ||= OrderBenefit
      .joins(:order)
      .where(benefit_id: loaded_benefits.map(&:id))
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
