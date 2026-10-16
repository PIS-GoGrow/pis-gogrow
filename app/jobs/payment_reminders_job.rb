# frozen_string_literal: true

class PaymentRemindersJob < ApplicationJob
  queue_as :default

  def perform(date: Date.current)
    PaymentReminders::Generate.call(date:)
  end
end
