# frozen_string_literal: true

module DebtReminders
  # Las mismas reglas que Eligibility, pero sobre el empleado entero: Recursos
  # Humanos no reclama una cuenta puntual sino toda la deuda vencida, así que el
  # tope y la espera se cuentan por empleado y no por cuenta.
  class EmployeeEligibility
    EVENT = "hr_debt_payment_reminder"

    attr_reader :consumer

    def initialize(consumer:, notifications: nil)
      @consumer = consumer
      @notifications = notifications
    end

    def eligible? = reason.nil?

    def reason
      return :no_debt if overdue_accounts.empty?
      return :limit_reached if sent_count >= Eligibility::MAX_REMINDERS
      return :cooldown if next_available_at && next_available_at > Time.current

      nil
    end

    # Las cuentas por las que tiene sentido reclamar: vencidas, impagas y sin un
    # comprobante esperando revisión.
    def overdue_accounts
      @overdue_accounts ||= consumer.accounts.select { Eligibility.new(account: it).debt_reason.nil? }
    end

    def amount = overdue_accounts.sum { it.amount || 0 }

    def sent_count = history.length

    def remaining = [ Eligibility::MAX_REMINDERS - sent_count, 0 ].max

    def next_available_at
      history.max_by(&:created_at)&.created_at&.+(Eligibility::COOLDOWN)
    end

    private

    def history
      @history ||= @notifications ||
        Notification.where(user: consumer.user, event: EVENT, notifiable: consumer).to_a
    end
  end
end
