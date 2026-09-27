# frozen_string_literal: true

class Provider::OrdersShowSerializer < ApplicationSerializer
  has_one :order, resource: Provider::OrderDetailSerializer
end
