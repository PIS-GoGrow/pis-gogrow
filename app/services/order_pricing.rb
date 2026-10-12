# frozen_string_literal: true

# Calcula cuánto paga el empleado por cada ítem de un pedido y qué beneficios
# cubren cada vianda. El subsidio base cubre las viandas que entran en el cupo
# mensual restante y cada subsidio especial, las que entran en sus usos
# restantes; los porcentajes de una misma vianda se suman con tope en 100%.
# Cada beneficio se reparte sobre las primeras viandas, en el orden de los ítems.
#
# Con held_by (al modificar una orden) se le devuelve a cada beneficio lo que
# esa orden ya tenía reservado, para no rechazarla contra su propio consumo.
class OrderPricing
  Line = Data.define(:price, :discounted_price, :benefits)
  Summary = Data.define(:total, :base, :specials)

  attr_reader :consumer

  def initialize(consumer, held_by: nil)
    @consumer = consumer
    @held_by = held_by
  end

  # items: [{ schedule:, quantity: }]. Devuelve un Line por ítem, con benefits
  # como { Benefit => viandas cubiertas }.
  def call(items)
    base_left = base_percentage.positive? ? consumer.remaining_monthly_benefit + base_held : 0
    special_left = special_benefits.to_h { [ it, remaining_uses(it) ] }

    items.map do |item|
      schedule = item[:schedule]
      quantity = item[:quantity]
      coverage = []

      base_units = [ quantity, base_left ].min
      base_left -= base_units
      coverage << [ consumer.monthly_benefit_for(schedule), base_percentage, base_units ]

      special_benefits.each do |benefit|
        next unless valid_on?(benefit, schedule.date)

        units = [ quantity, special_left[benefit] ].compact.min
        special_left[benefit] -= units if special_left[benefit]
        coverage << [ benefit, benefit.percentage, units ]
      end

      line_for(schedule.menu.price, quantity, coverage)
    end
  end

  def base_percentage
    @base_percentage ||= consumer.current_monthly_benefit&.percentage.to_i.clamp(0, 100)
  end

  def special_benefits
    @special_benefits ||= consumer.benefits.current
      .where(benefit_configuration: BenefitConfiguration.special.active)
      .order(:id)
      .to_a
  end

  # nil significa usos ilimitados, como el de antigüedad.
  def remaining_uses(benefit)
    return if benefit.amount.nil?

    [ benefit.amount - special_used.fetch(benefit.id, 0) + special_held.fetch(benefit.id, 0), 0 ].max
  end

  # Lo que le corresponde hoy a una vianda que entre en todos los cupos: el base
  # y los especiales vigentes que todavía tienen usos. nil si no tiene ninguno.
  def summary(date: Date.current)
    specials = special_benefits.select { valid_on?(it, date) && remaining_uses(it) != 0 }
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
  def line_for(unit_price, quantity, coverage)
    discounted_price = (0...quantity).sum do |unit|
      percentage = coverage.sum { |_benefit, benefit_percentage, units| unit < units ? benefit_percentage : 0 }
      unit_price * (100 - percentage.clamp(0, 100)) / 100
    end

    Line.new(
      price: unit_price * quantity,
      discounted_price: discounted_price.round(2),
      benefits: coverage.filter_map { |benefit, _percentage, units| [ benefit, units ] if benefit && units.positive? }.to_h
    )
  end

  def valid_on?(benefit, date)
    benefit.due_date.nil? || benefit.due_date >= date
  end

  def special_used
    @special_used ||= OrderBenefit
      .joins(:order)
      .where(benefit_id: special_benefits.map(&:id))
      .where.not(orders: { status: [ :cancelled, :rejected ] })
      .group(:benefit_id)
      .sum(:benefit_used)
  end

  def special_held
    @special_held ||= @held_by ? @held_by.order_benefits.where(benefit_id: special_benefits.map(&:id)).group(:benefit_id).sum(:benefit_used) : {}
  end

  def base_held
    @held_by&.subsidized_units_held.to_i
  end
end
