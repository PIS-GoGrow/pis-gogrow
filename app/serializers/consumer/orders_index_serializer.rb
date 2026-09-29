# frozen_string_literal: true

class Consumer::OrdersIndexSerializer < ApplicationSerializer
  has_many :upcoming_orders, resource: OrderSerializer
  has_many :past_orders, resource: OrderSerializer
end
