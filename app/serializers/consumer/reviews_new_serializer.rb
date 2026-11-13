# frozen_string_literal: true

class Consumer::ReviewsNewSerializer < ApplicationSerializer
  has_one :order, resource: OrderSerializer
end
