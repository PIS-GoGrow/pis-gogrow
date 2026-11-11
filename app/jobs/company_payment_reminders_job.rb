# frozen_string_literal: true

class CompanyPaymentRemindersJob < ApplicationJob
  queue_as :default

  def perform(date: Date.current)
    CompanyPaymentNotifications.remind!(date:)
    InvoiceReminders::MissingNotices.remind!(date:)
  end
end
