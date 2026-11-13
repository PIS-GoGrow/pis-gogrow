# frozen_string_literal: true

class Provider::InsightsIndexSerializer < ApplicationSerializer
  attributes :from,
    :to,
    :default_from,
    :default_to,
    :min,
    :max,
    :month_label,
    :presets,
    :orders_count,
    :dishes_count,
    :average_rating,
    :top_dishes,
    :top_rated_dishes

  typelize from: :string
  typelize to: :string
  typelize default_from: :string
  typelize default_to: :string
  typelize min: :string
  typelize max: :string
  typelize month_label: :string?
  typelize presets: "Array<{ key: 'today' | 'yesterday' | 'this_week' | 'this_month' | 'last_month'; from: string; to: string }>"
  typelize orders_count: :number
  typelize dishes_count: :number
  typelize average_rating: :number?
  typelize top_dishes: "Array<{ id: number; name: string; orders_count: number }>"
  typelize top_rated_dishes: "Array<{ id: number; name: string; rating: number }>"
end
