# frozen_string_literal: true

class Provider::InsightsIndexSerializer < ApplicationSerializer
  attributes :period,
    :current_period,
    :periods,
    :orders_count,
    :dishes_count,
    :average_rating,
    :top_dishes,
    :top_rated_dishes

  typelize period: :string
  typelize current_period: :string
  typelize periods: "Array<{ key: string; label: string }>"
  typelize orders_count: :number
  typelize dishes_count: :number
  typelize average_rating: :number?
  typelize top_dishes: "Array<{ id: number; name: string; orders_count: number }>"
  typelize top_rated_dishes: "Array<{ id: number; name: string; rating: number }>"
end
