# frozen_string_literal: true

module DebtReminders
  class Request
    class Ineligible < StandardError
      attr_reader :reason

      def initialize(reason)
        @reason = reason
        super(reason.to_s)
      end
    end

    class CreationFailed < StandardError; end

    def self.call(account:, requested_by:)
      raise ActiveRecord::RecordNotFound unless requested_by.provider&.id == account.provider_id

      account.with_lock do
        eligibility = Eligibility.new(account:)
        raise Ineligible, eligibility.reason unless eligibility.eligible?

        recipient = account.owner.user
        Notification.close_by(event: Eligibility::EVENT, notifiable: account, user: recipient)

        notification = Notifier.call(
          event_key: Eligibility::EVENT,
          user: recipient,
          notifiable: account,
          description_data: {
            amount: ActionController::Base.helpers.number_to_currency(
              account.amount,
              unit: "$",
              format: "%u%n",
              precision: account.amount.frac.zero? ? 0 : 2,
              delimiter: ".",
              separator: ","
            ),
            provider: account.provider.user.name,
            period: I18n.l(account.month, format: :month_name_year).downcase
          }
        )
        raise CreationFailed unless notification

        notification
      end
    end
  end
end
