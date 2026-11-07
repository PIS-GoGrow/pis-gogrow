# frozen_string_literal: true

class Consumer::OrdersIndexSerializer < ApplicationSerializer
  has_many :upcoming_orders, resource: OrderSerializer
  has_many :past_orders, resource: OrderSerializer, inertia: { scroll: :past_orders_page }
  has_many :providers, resource: ProviderSerializer
end
