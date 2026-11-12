# frozen_string_literal: true

class Provider::InsightsController < Provider::InertiaController
  RATE_LIMIT_COUNT = 3
  RATE_LIMIT_WINDOW = 15.minutes

  def self.rate_limit_store
    configured_store = Rails.configuration.x.rate_limit_store
    configured_store.is_a?(ActiveSupport::Cache::Store) ? configured_store : Rails.cache
  end
  private_class_method :rate_limit_store

  wrap_parameters false

  rate_limit to: RATE_LIMIT_COUNT, within: RATE_LIMIT_WINDOW, only: :create_conclusions, name: "provider-review-insights",
             by: -> { Current.user&.id || request.remote_ip }, store: rate_limit_store,
             with: -> { render_conclusions_error("rate_limited", :too_many_requests) }

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

  def create_conclusions
    return render_conclusions_error("invalid_request", :bad_request) unless conclusions_parameters_only?

    range = conclusions_range
    return render_conclusions_error("invalid_period", :unprocessable_content) unless range

    result = Provider::ReviewInsightsConclusions.new(range:).call
    return render_generation_error(result.fetch(:error)) unless result[:ok]

    generated_at = Time.current
    render json: {
      success: true,
      text: result.fetch(:text),
      period: result.fetch(:period),
      review_count: result.fetch(:review_count),
      generated_at: generated_at.iso8601,
      generated_at_label: DateFormat.long_with_time(generated_at, inline: true),
      generated_by_ai: true
    }
  end

  private

  def conclusions_parameters_only?
    params.except(:controller, :action, :format, :desde, :hasta, :authenticity_token).empty?
  end

  def conclusions_range
    from = conclusions_date(params[:desde])
    to = conclusions_date(params[:hasta])
    return unless from && to && from <= to

    first_delivery = Provider::ActivitySummary.first_delivery_date(Current.user.provider)
    minimum = [ first_delivery, Date.current.beginning_of_month ].compact.min
    maximum = Date.current.end_of_month
    from..to if from >= minimum && to <= maximum
  end

  def conclusions_date(value)
    return unless value.is_a?(String) && value.match?(/\A[0-9]{4}-[0-9]{2}-[0-9]{2}\z/)

    Date.iso8601(value)
  rescue Date::Error
    nil
  end

  def render_generation_error(error)
    code = error[:code]
    status = case code
    when "insufficient_data", "invalid_payload" then :unprocessable_content
    when "rate_limited" then :too_many_requests
    when "timeout" then :gateway_timeout
    when "invalid_response", "refused" then :bad_gateway
    else :service_unavailable
    end
    code = "generation_unavailable" unless %w[
      insufficient_data configuration_missing authentication_failed permission_or_billing spend_limit_reached
      rate_limited timeout external_unavailable invalid_response refused invalid_payload payload_too_large unexpected_error
    ].include?(code)
    render_conclusions_error(code, status, review_count: error[:review_count])
  end

  def render_conclusions_error(code, status, review_count: nil)
    message_key = %w[invalid_request invalid_period rate_limited insufficient_data].include?(code) ? code : "generation_unavailable"
    error = { code:, message: t("review_insights.errors.#{message_key}") }
    error[:review_count] = review_count if code == "insufficient_data"
    render json: { success: false, error: }, status:
  end

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
