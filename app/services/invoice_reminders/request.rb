# frozen_string_literal: true

# El recordatorio que RR. HH. le manda a un proveedor para que cargue la factura
# de un período ya cerrado.
module InvoiceReminders
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
      raise ActiveRecord::RecordNotFound unless account.owner == requested_by.admin&.company

      account.with_lock do
        eligibility = Eligibility.new(account: account.reload)
        raise Ineligible, eligibility.reason unless eligibility.eligible?

        recipient = account.provider.user
        raise CreationFailed unless recipient

        Notification.close_by(event: Eligibility::EVENT, notifiable: account, user: recipient)

        notification = Notifier.call(
          event_key: Eligibility::EVENT,
          user: recipient,
          notifiable: account,
          description_data: {
            company: account.owner.name,
            period: I18n.l(account.month, format: :month_name_year).downcase
          }
        )
        raise CreationFailed unless notification

        notification
      end
    end

    def self.close(invoice)
      account = invoice.account
      user = account.provider.user
      return unless user

      Notification.close_by(event: Eligibility::EVENT, notifiable: account, user:)
    end
  end
end
