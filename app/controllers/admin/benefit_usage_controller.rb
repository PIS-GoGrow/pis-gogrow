# frozen_string_literal: true

class Admin::BenefitUsageController < Admin::InertiaController
  rate_limit to: 3, within: 15.minutes, only: :create_summary, name: "benefit-usage-summary",
             by: -> { Current.user&.id || request.remote_ip }, store: Rails.configuration.x.rate_limit_store || Rails.cache,
             with: -> { render_error("rate_limited", :too_many_requests) }

  def show
    month = requested_month(default_current: true)
    return render_error("invalid_month", :unprocessable_content) unless month

    render json: safe_statistics(month)
  end

  def create_summary
    return render_error("invalid_request", :bad_request) unless summary_parameters_only?

    month = requested_month
    return render_error("invalid_month", :unprocessable_content) unless month

    payload = AdminBenefitUsageAiPayload.new(stats: statistics(month))
    result = AdminBenefitUsageSummary.new(payload:).call
    return render_summary_error(result.dig(:error, :code)) unless result[:ok]

    render json: {
      success: true,
      text: result.fetch(:text),
      month: month.strftime("%Y-%m"),
      generated_at: Time.current.iso8601,
      generated_by_ai: true
    }
  end

  private

  def statistics(month)
    AdminBenefitUsageStats.new(company: Current.user.admin.company, month:).to_h
  end

  def safe_statistics(month)
    AdminBenefitUsagePresentationPayload.new(stats: statistics(month)).to_h
  end

  def requested_month(default_current: false)
    return Date.current.beginning_of_month if default_current && !params.key?(:month)

    value = params[:month]
    return unless value.is_a?(String) && value.match?(/\A[0-9]{4}-(?:0[1-9]|1[0-2])\z/)

    year = value.first(4).to_i
    return unless year.positive?

    month = Date.new(year, value.last(2).to_i, 1)
    month if month <= Date.current.beginning_of_month
  end

  def summary_parameters_only?
    params.except(:controller, :action, :format, :month, :authenticity_token).empty?
  end

  def render_summary_error(code)
    status = case code
    when "configuration_missing", "permission_or_billing", "spend_limit_reached", "external_unavailable"
      :service_unavailable
    when "rate_limited"
      :too_many_requests
    when "timeout"
      :gateway_timeout
    else
      :bad_gateway
    end
    code = "summary_unavailable" unless %w[
      configuration_missing authentication_failed permission_or_billing spend_limit_reached rate_limited
      timeout external_unavailable invalid_response refused invalid_payload payload_too_large
    ].include?(code)
    render_error(code, status)
  end

  def render_error(code, status)
    message_key = case code
    when "invalid_month", "invalid_request", "rate_limited" then code
    else "summary_unavailable"
    end
    render json: { success: false, error: { code:, message: t("benefit_usage.errors.#{message_key}") } }, status:
  end
end
