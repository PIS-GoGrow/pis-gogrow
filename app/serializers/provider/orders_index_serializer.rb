# frozen_string_literal: true

class Provider::OrdersIndexSerializer < ApplicationSerializer
  attributes :today

  typelize today: :string

  has_many :upcoming_orders, resource: Provider::OrderSerializer
  has_many :past_orders, resource: Provider::OrderSerializer
end
