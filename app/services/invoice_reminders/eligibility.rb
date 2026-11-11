# frozen_string_literal: true

module InvoiceReminders
  class Eligibility
    COOLDOWN = 3.days
    EVENT = "invoice_reminder"

    attr_reader :account

    def initialize(account:, last_sent_at: :unknown)
      @account = account
      @last_sent_at = last_sent_at
    end

    def eligible? = reason.nil?

    def reason
      return :not_company unless account.company?
      return :invoiced if account.invoices.any? { it.pending? || it.approved? }
      return :current_month unless account.month < Date.current.beginning_of_month
      return :cooldown if next_available_at&.future?

      nil
    end

    def next_available_at
      last_sent_at&.+(COOLDOWN)
    end

    private

    def last_sent_at
      return @last_sent_at unless @last_sent_at == :unknown

      @last_sent_at = Notification.where(event: EVENT, notifiable: account).maximum(:created_at)
    end
  end
end
