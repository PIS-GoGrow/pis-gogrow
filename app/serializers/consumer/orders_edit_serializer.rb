# frozen_string_literal: true

class Consumer::OrdersEditSerializer < ApplicationSerializer
  has_one :order, resource: OrderSerializer

  attributes :schedule, :delivery_addresses, :benefit_ids

  typelize schedule: "{ id: number; date: string; remaining: number; sold_out: boolean; orders_closed: boolean; menu: { id: number; name: string; description: string | null; price: number; provider_id: number; saved_menu_id: number; option_groups: Array<{ id: number; name: string; options: string[]; limit: number; required: boolean }>; provider_name: string; home_delivery: boolean; rating_average: number | null; rating_count: number; reviews: Array<{ id: number; author: string | null; description: string | null; rating: number; created_at: string }> } }"
  typelize benefit_ids: "number[]"
  typelize delivery_addresses: "Array<{ id: string; label: string; address: string }>"
end
