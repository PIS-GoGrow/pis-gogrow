# frozen_string_literal: true

class OrdersShowSerializer < ApplicationSerializer
  has_one :order, resource: OrderSerializer
end
