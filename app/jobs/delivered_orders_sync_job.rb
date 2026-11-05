# frozen_string_literal: true

class DeliveredOrdersSyncJob < ApplicationJob
  queue_as :default

  def perform(date: Date.current)
    Account.where(month: date.beginning_of_month)
           .where(id: OrderAccount.joins(:order).merge(Order.confirmed.where(delivery_date: ..date)).select(:account_id))
           .find_each(&:sync_amount!)
  end
end
