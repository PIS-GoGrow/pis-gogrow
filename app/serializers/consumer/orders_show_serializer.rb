# frozen_string_literal: true

class Consumer::OrdersShowSerializer < ApplicationSerializer
  has_one :order, resource: OrderSerializer

  attributes :delivery_addresses, :max_quantity

  typelize delivery_addresses: "Array<{ id: string; label: string; address: string }>"
  typelize max_quantity: :number
end
