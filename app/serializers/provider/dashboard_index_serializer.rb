# frozen_string_literal: true

class Provider::DashboardIndexSerializer < ApplicationSerializer
  attributes :today,
    :today_orders_count,
    :pending_orders_count,
    :office_orders_count,
    :home_orders_count,
    :order_deadline,
    :month_orders_count,
    :month_dishes_count,
    :average_rating

  typelize today: :string
  typelize today_orders_count: :number
  typelize pending_orders_count: :number
  typelize office_orders_count: :number
  typelize home_orders_count: :number
  typelize order_deadline: :string?
  typelize month_orders_count: :number
  typelize month_dishes_count: :number
  typelize average_rating: :number?

  has_one :provider, serializer: Provider::DashboardProviderSerializer
end
