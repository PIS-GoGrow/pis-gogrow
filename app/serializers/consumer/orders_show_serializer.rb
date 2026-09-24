# frozen_string_literal: true

class Consumer::OrdersShowSerializer < ApplicationSerializer
  has_one :order, resource: OrderSerializer
end
