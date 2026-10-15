# frozen_string_literal: true

module PaymentReminders
  class CloseActive
    EVENTS = %w[payment_available payment_due_soon].freeze

    def self.call(account:)
      return unless account.owner_type == "Consumer"

      account.owner.user.notifications
             .active
             .where(event: EVENTS, notifiable: account)
             .find_each(&:close!)
    end
  end
end
