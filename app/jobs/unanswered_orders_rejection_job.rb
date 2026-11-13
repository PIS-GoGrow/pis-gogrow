# frozen_string_literal: true

class UnansweredOrdersRejectionJob < ApplicationJob
  queue_as :default

  def perform
    Provider.where.not(order_deadline: nil).find_each do |provider|
      next unless provider.response_deadline_passed_today?

      provider.orders.pending.where(delivery_date: Date.current).find_each(&:reject_unanswered!)
    end
  end
end
