# frozen_string_literal: true

class Provider::InsightsController < Provider::InertiaController
  include SelectedPeriod

  def index
    provider = Current.user.provider
    range = select_period(Provider::ActivitySummary.first_delivery_date(provider))
    summary = Provider::ActivitySummary.new(provider, range)

    @orders_count = summary.orders_count
    @dishes_count = summary.dishes_count
    @average_rating = summary.average_rating
    @top_dishes = summary.top_dishes.map { { id: it.id, name: it.name, orders_count: it.orders_count } }
    @top_rated_dishes = summary.top_rated_dishes.map { { id: it.id, name: it.name, rating: it.rating } }
  end
end
