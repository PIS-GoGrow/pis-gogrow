# frozen_string_literal: true

class Consumer::OrdersShowSerializer < ApplicationSerializer
  has_one :order, resource: OrderSerializer

  attributes :delivery_addresses, :max_quantity, :option_groups

  typelize delivery_addresses: "Array<{ id: string; label: string; address: string }>"
  typelize max_quantity: :number
  typelize option_groups: "Array<{ id: number; name: string; options: string[]; limit: number }>"
  attributes :delivery_addresses, :max_quantity, :editing

  typelize delivery_addresses: "Array<{ id: string; label: string; address: string }>"
  typelize max_quantity: :number
  typelize editing: :boolean
end
