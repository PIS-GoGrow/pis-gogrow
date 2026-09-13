# frozen_string_literal: true

class Provider::OrdersIndexSerializer < ApplicationSerializer
  has_many :orders, resource: Provider::OrderSerializer
end
