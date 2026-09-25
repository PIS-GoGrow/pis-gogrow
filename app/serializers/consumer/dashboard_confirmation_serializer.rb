# frozen_string_literal: true

class Consumer::DashboardConfirmationSerializer < ApplicationSerializer
  attributes :total, :orders

  typelize total: :number
  typelize orders: "Array<{ id: number; date: string; address: string; delivery_method: string; provider_name: string; name: string; quantity: number; discounted_price: number }>"
end
