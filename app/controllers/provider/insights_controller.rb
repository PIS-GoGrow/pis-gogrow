# frozen_string_literal: true

class Provider::InsightsController < Provider::InertiaController
  def index
    provider = Current.user.provider
    default = Date.current.all_month
    first_delivery = Provider::ActivitySummary.first_delivery_date(provider)
    limits = [ first_delivery, default.first ].compact.min..default.last
    range = requested_range(limits) || default
    summary = Provider::ActivitySummary.new(provider, range)

    @from = range.first.iso8601
    @to = range.last.iso8601
    @default_from = default.first.iso8601
    @default_to = default.last.iso8601
    @min = limits.first.iso8601
    @max = limits.last.iso8601
    @month_label = (I18n.l(range.first, format: :month_name_year).capitalize if range == range.first.all_month)
    @presets = presets.map { |key, preset| { key:, from: preset.first.iso8601, to: preset.last.iso8601 } }
    @orders_count = summary.orders_count
    @dishes_count = summary.dishes_count
    @average_rating = summary.average_rating
    @top_dishes = summary.top_dishes.map { { id: it.id, name: it.name, orders_count: it.orders_count } }
    @top_rated_dishes = summary.top_rated_dishes.map { { id: it.id, name: it.name, rating: it.rating } }
  end

  private

  # ?desde=AAAA-MM-DD&hasta=AAAA-MM-DD. Un rango mal escrito o invertido no es un
  # error del proveedor: se muestra el mes actual. Lo que quede fuera de los
  # límites se recorta.
  def requested_range(limits)
    from = Date.iso8601(params[:desde].to_s)
    to = Date.iso8601(params[:hasta].to_s)
    return if from > to

    range = [ from, limits.first ].max..[ to, limits.last ].min
    range unless range.first > range.last
  rescue Date::Error
    nil
  end

  # La semana empieza el domingo, como el calendario.
  def presets
    today = Date.current

    {
      today: today..today,
      yesterday: today.yesterday..today.yesterday,
      this_week: today.beginning_of_week(:sunday)..today,
      this_month: today.all_month,
      last_month: today.prev_month.all_month
    }
  end
end
