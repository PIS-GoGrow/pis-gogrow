# frozen_string_literal: true

module DebtReminders
  class Eligibility
    COOLDOWN = 3.days
    MAX_REMINDERS = 10
    MIN_AMOUNT = 0
    EVENT = "debt_payment_reminder"

    attr_reader :account

    def initialize(account:, notifications: nil)
      @account = account
      @notifications = notifications
    end

    def eligible? = reason.nil?

    def reason = debt_reason || history_reason

    # Motivos que dependen del estado de la cuenta y no de los recordatorios ya
    # enviados. EmployeeEligibility los reusa para quedarse con las cuentas
    # vencidas de un empleado.
    def debt_reason
      return :not_consumer unless account.owner_type == "Consumer"
      return :no_debt unless account.amount.to_d > MIN_AMOUNT
      return :not_overdue unless account.due_date < Date.current
      return :payment_under_review if account.collection_status == "submitted"
      return :paid unless account.collection_status.in?(%w[pending rejected partial])

      nil
    end

    def sent_count = history.length

    def remaining = [ MAX_REMINDERS - sent_count, 0 ].max

    def next_available_at
      last_notified_at&.+(COOLDOWN)
    end

    private

    # Rechazar un comprobante, o aceptarlo solo en parte, ya le avisa al
    # empleado: cuenta como un recordatorio recién enviado.
    def last_notified_at
      [ history.max_by(&:created_at)&.created_at, last_issue_at ].compact.max
    end

    def last_issue_at
      last = account.last_payment
      last.updated_at if last&.rejected? || last&.partial?
    end

    def history_reason
      return :limit_reached if sent_count >= MAX_REMINDERS
      return :cooldown if next_available_at && next_available_at > Time.current

      nil
    end

    def history
      @history ||= if account.owner_type != "Consumer"
        []
      elsif @notifications
        @notifications
      else
        Notification.where(user: account.owner.user, event: EVENT, notifiable: account).to_a
      end
    end
  end
end
