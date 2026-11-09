# frozen_string_literal: true

class Provider::DashboardIndexSerializer < ApplicationSerializer
  attributes :today,
    :today_orders_count,
    :pending_orders_count,
    :office_orders_count,
    :home_orders_count,
    :order_deadline,
    :order_deadline_passed_today,
    :month_orders_count,
    :month_dishes_count,
    :average_rating,
    :top_rated,
    :completed_sections_count,
    :sections_total

  typelize today: :string
  typelize today_orders_count: :number
  typelize pending_orders_count: :number
  typelize office_orders_count: :number
  typelize home_orders_count: :number
  typelize order_deadline: :string?
  typelize order_deadline_passed_today: :boolean
  typelize month_orders_count: :number
  typelize month_dishes_count: :number
  typelize average_rating: :number?
  typelize top_rated: "Array<{ name: string; rating: number }>"
  typelize completed_sections_count: :number
  typelize sections_total: :number

  has_one :provider, serializer: Provider::DashboardProviderSerializer
end
