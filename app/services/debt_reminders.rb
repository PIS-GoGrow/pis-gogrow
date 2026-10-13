# frozen_string_literal: true

# Recordatorios de deuda vencida. El proveedor reclama una cuenta puntual
# (Eligibility y Request); Recursos Humanos reclama toda la deuda vencida de un
# empleado (EmployeeEligibility y EmployeeRequest).
module DebtReminders
  # El monto viaja dentro del texto de la notificación, así que se formatea acá
  # y no en el frontend.
  def self.format_amount(amount)
    ActionController::Base.helpers.number_to_currency(
      amount,
      unit: "$",
      format: "%u%n",
      precision: amount.frac.zero? ? 0 : 2,
      delimiter: ".",
      separator: ","
    )
  end
end
