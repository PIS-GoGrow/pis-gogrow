# frozen_string_literal: true

class Provider::InsightsController < Provider::InertiaController
  # ?period=AAAA-MM. Un período mal escrito, futuro o anterior a la primera
  # entrega no es un error del proveedor: se muestra el mes actual.
  def index
    provider = Current.user.provider
    months = Provider::ActivitySummary.months(provider)
    month = months.find { it.strftime("%Y-%m") == params[:period] } || months.first
    summary = Provider::ActivitySummary.new(provider, month)

    @period = month.strftime("%Y-%m")
    @current_period = months.first.strftime("%Y-%m")
    @periods = months.map { { key: it.strftime("%Y-%m"), label: I18n.l(it, format: :month_name_year).capitalize } }
    @orders_count = summary.orders_count
    @dishes_count = summary.dishes_count
    @average_rating = summary.average_rating
    @top_dishes = summary.top_dishes.map { { id: it.id, name: it.name, orders_count: it.orders_count } }
    @top_rated_dishes = summary.top_rated_dishes.map { { id: it.id, name: it.name, rating: it.rating } }
  end
end
