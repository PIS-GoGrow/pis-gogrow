# frozen_string_literal: true

class Admin::BenefitUsageController < Admin::InertiaController
  def self.rate_limit_store
    configured_store = Rails.configuration.x.rate_limit_store
    configured_store.is_a?(ActiveSupport::Cache::Store) ? configured_store : Rails.cache
  end
  private_class_method :rate_limit_store

  wrap_parameters false

  rate_limit to: 3, within: 15.minutes, only: :create_summary, name: "benefit-usage-summary",
             by: -> { Current.user&.id || request.remote_ip }, store: rate_limit_store,
             with: -> { render_error("rate_limited", :too_many_requests) }

  def analysis
    month = requested_month(default_current: true)
    return redirect_to admin_benefit_usage_analysis_path unless month

    current = Date.current.beginning_of_month
    @month = month.strftime("%Y-%m")
    @current_month = current.strftime("%Y-%m")
    @months = month_options((12.times.map { current << it } + [ month ]).uniq.sort.reverse)
  end

  def show
    month = requested_month(default_current: true)
    return render_error("invalid_month", :unprocessable_content) unless month

    if month == Date.current.beginning_of_month
      company = Current.user.admin.company
      stats = AdminBenefitUsageStats.new(company:, month:).to_h
      response.set_header("X-Benefit-Usage-Source", "current_calculation")
      response.set_header("X-Benefit-Usage-State", "provisional")
      render json: AdminBenefitUsagePresentationPayload.new(stats:).to_h.merge(
        analysis_revision: analysis_revision(company:, month:, source: "current_calculation", data: stats)
      )
    else
      company = Current.user.admin.company
      history = AdminBenefitUsageHistory.new(company:, month:).to_h
      response.set_header("X-Benefit-Usage-Source", history.dig(:period, :source))
      response.set_header("X-Benefit-Usage-State", history.dig(:period, :state))
      render json: AdminBenefitUsageHistoricalPresentation.new(history:).to_h.merge(
        analysis_revision: analysis_revision(company:, month:, source: history.dig(:period, :source), data: history)
      )
    end
  end

  def create_summary
    return render_error("invalid_request", :bad_request) unless summary_parameters_only?

    month = requested_month
    return render_error("invalid_month", :unprocessable_content) unless month

    company = Current.user.admin.company
    payload = if month == Date.current.beginning_of_month
      stats = AdminBenefitUsageStats.new(company:, month:).to_h
      return render_error("stale_analysis", :conflict) if params.key?(:analysis_revision) &&
        params[:analysis_revision] != analysis_revision(company:, month:, source: "current_calculation", data: stats)

      AdminBenefitUsageAiPayload.new(stats:)
    else
      history = AdminBenefitUsageHistory.new(company:, month:).to_h
      return render_error("stale_analysis", :conflict) unless params[:analysis_revision].is_a?(String) &&
        params[:analysis_revision] == analysis_revision(company:, month:, source: history.dig(:period, :source), data: history)

      AdminBenefitUsageAiPayload.new(history:)
    end
    result = AdminBenefitUsageSummary.new(payload:).call
    return render_summary_error(result.dig(:error, :code)) unless result[:ok]

    generated_at = Time.current
    render json: {
      success: true,
      text: result.fetch(:text),
      month: month.strftime("%Y-%m"),
      generated_at: generated_at.iso8601,
      generated_at_label: DateFormat.long_with_time(generated_at, inline: true),
      generated_by_ai: true
    }
  end

  private

  def analysis_revision(company:, month:, source:, data:)
    AdminBenefitUsageAnalysisRevision.call(company:, month:, source:, data:)
  end

  def requested_month(default_current: false)
    return Date.current.beginning_of_month if default_current && !params.key?(:month)

    value = params[:month]
    return unless value.is_a?(String) && value.match?(/\A[0-9]{4}-(?:0[1-9]|1[0-2])\z/)

    year = value.first(4).to_i
    return unless year.positive?

    month = Date.new(year, value.last(2).to_i, 1)
    current = Date.current.beginning_of_month
    month if month.between?(current << 11, current)
  end

  def summary_parameters_only?
    params.except(:controller, :action, :format, :month, :analysis_revision, :authenticity_token).empty?
  end

  def render_summary_error(code)
    status = case code
    when "configuration_missing", "permission_or_billing", "spend_limit_reached", "external_unavailable"
      :service_unavailable
    when "rate_limited"
      :too_many_requests
    when "timeout"
      :gateway_timeout
    when "insufficient_data"
      :unprocessable_content
    else
      :bad_gateway
    end
    code = "summary_unavailable" unless %w[
      configuration_missing authentication_failed permission_or_billing spend_limit_reached rate_limited
      timeout external_unavailable invalid_response refused invalid_payload payload_too_large insufficient_data
    ].include?(code)
    render_error(code, status)
  end

  def render_error(code, status)
    message_key = case code
    when "invalid_month", "invalid_request", "rate_limited", "insufficient_data", "stale_analysis" then code
    else "summary_unavailable"
    end
    render json: { success: false, error: { code:, message: t("benefit_usage.errors.#{message_key}") } }, status:
  end
end
