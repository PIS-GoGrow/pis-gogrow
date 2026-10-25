# frozen_string_literal: true

class Consumer::OrdersEditSerializer < ApplicationSerializer
  has_one :order, resource: OrderSerializer

  attributes :schedule, :delivery_addresses

  typelize schedule: "{ id: number; date: string; remaining: number; sold_out: boolean; orders_closed: boolean; menu: { id: number; name: string; description: string | null; price: number; option_groups: Array<{ id: number; name: string; options: string[]; limit: number; required: boolean }>; provider_name: string; home_delivery: boolean; reviews: Array<{ id: number; description: string | null; rating: number | null; created_at: string }> } }"
  typelize delivery_addresses: "Array<{ id: string; label: string; address: string }>"
end
