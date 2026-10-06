# frozen_string_literal: true

class Consumer::ProfilesController < Consumer::InertiaController
  # El nombre, el email y la foto ya viajan en las props compartidas: acá solo
  # hace falta el beneficio, que es lo que esta pantalla agrega.
  def show
    consumer = Current.user.consumer
    benefit = consumer.current_monthly_benefit

    @benefit = benefit && {
      percentage: benefit.percentage.to_i,
      monthly_limit: consumer.monthly_benefit_available,
      monthly_remaining: consumer.remaining_monthly_benefit,
      max_price: benefit.benefit_configuration.benefit_rules.find { it.is_a?(MonthlyBenefit) }&.max_price&.to_f,
      due_date: benefit.due_date && I18n.l(benefit.due_date, format: "%d/%m/%Y")
    }
  end
end
