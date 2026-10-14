# frozen_string_literal: true

module PaymentReminders
  class Generate
    DAYS_BEFORE_DUE = 3
    MAX_REMINDERS_PER_EVENT = 1

    AVAILABLE_EVENT = "payment_available"
    DUE_SOON_EVENT = "payment_due_soon"

    ELIGIBLE_STATUSES = %w[pending rejected].freeze

    def self.call(date: Date.current)
      new(date:).call
    end

    def initialize(date:)
      @date = date.to_date
    end

    def call
      accounts.find_each do |account|
        notify_if_due(account)
      end
    end

    private

    attr_reader :date

    def accounts
      Account
        .where(owner_type: "Consumer", month: date.prev_month.beginning_of_month)
        .where("amount > 0")
        .includes(:payments, provider: :user)
    end

    def notify_if_due(account)
      return unless account.collection_status.in?(ELIGIBLE_STATUSES)

      event = event_for(account)
      return unless event

      user = account.owner.user
      return if already_notified?(account:, user:, event:)

      notification = Notifier.call(
        event_key: event,
        user:,
        notifiable: account,
        description_data: {
          amount: formatted_amount(account.amount),
          provider: account.provider.user.name,
          due_date: I18n.l(account.due_date, format: "%d/%m/%Y"),
          days: DAYS_BEFORE_DUE
        }
      )

      Rails.logger.error(
        "[PaymentReminders::Generate] No se pudo crear #{event} para Account##{account.id}"
      ) unless notification
    end

    def event_for(account)
      return AVAILABLE_EVENT if date == account.month.next_month.beginning_of_month
      return DUE_SOON_EVENT if date == account.due_date - DAYS_BEFORE_DUE.days

      nil
    end

    def already_notified?(account:, user:, event:)
      Notification.where(
        user:,
        notifiable: account,
        event:
      ).count >= MAX_REMINDERS_PER_EVENT
    end

    def formatted_amount(amount)
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
end
