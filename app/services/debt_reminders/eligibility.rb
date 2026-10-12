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

    def reason
      return :not_consumer unless account.owner_type == "Consumer"
      return :no_debt unless account.amount.to_d > MIN_AMOUNT
      return :not_overdue unless account.due_date < Date.current
      return :payment_under_review if account.collection_status == "submitted"
      return :paid unless account.collection_status.in?(%w[pending rejected])
      return :limit_reached if sent_count >= MAX_REMINDERS
      return :cooldown if next_available_at && next_available_at > Time.current

      nil
    end

    def sent_count = history.length

    def remaining = [ MAX_REMINDERS - sent_count, 0 ].max

    def next_available_at
      history.max_by(&:created_at)&.created_at&.+(COOLDOWN)
    end

    private

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
