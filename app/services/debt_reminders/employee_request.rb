# frozen_string_literal: true

module DebtReminders
  # El recordatorio que Recursos Humanos le manda a un empleado por su deuda
  # vencida. A diferencia del del proveedor, es uno solo por empleado y suma
  # todas sus cuentas vencidas.
  class EmployeeRequest
    def self.call(consumer:, requested_by:)
      raise ActiveRecord::RecordNotFound unless requested_by.admin&.company_id == consumer.company_id

      consumer.with_lock do
        eligibility = EmployeeEligibility.new(consumer:)
        raise Request::Ineligible, eligibility.reason unless eligibility.eligible?

        recipient = consumer.user
        Notification.close_by(event: EmployeeEligibility::EVENT, notifiable: consumer, user: recipient)

        notification = Notifier.call(
          event_key: EmployeeEligibility::EVENT,
          user: recipient,
          notifiable: consumer,
          description_data: {
            amount: Account.format_amount(eligibility.amount),
            providers: eligibility.provider_names.to_sentence
          }
        )
        raise Request::CreationFailed unless notification

        notification
      end
    end

    # El recordatorio no requiere acción, así que el empleado puede cerrarlo, pero
    # tampoco tiene sentido que siga ahí cuando ya no debe nada: esto lo cierra
    # solo al aprobarse el pago que salda la última cuenta vencida.
    def self.close_if_settled(consumer)
      return if EmployeeEligibility.new(consumer:).overdue_accounts.any?

      Notification.close_by(
        event: EmployeeEligibility::EVENT,
        notifiable: consumer,
        user: consumer.user
      )
    end
  end
end
