# frozen_string_literal: true

class Consumer::OrdersShowSerializer < ApplicationSerializer
  typelize historical: :boolean
  attributes :historical

  has_one :order, resource: OrderSerializer
end
