# frozen_string_literal: true

class AdminBenefitUsageAiPayload
  WARNING_CODES = %w[
    employee_counts_use_current_roster historical_roster_incomplete historical_status_at_close_unavailable
    eligibility_unknown monthly_quota_unknown historical_discounts_without_benefit_records
    pending_discounts_without_benefit_records monthly_benefit_units_exceed_order_amount
    benefit_consumer_mismatch
    monthly_usage_exceeds_quota monthly_usage_outside_eligibility company_subsidy_amount_unreliable
    confirmed_meals_unreliable historical_trends_from_retained_records open_month_partial
    trend_monthly_subsidy_unknown trend_company_subsidy_unknown trend_confirmed_meals_unknown
  ].freeze
  INDICATORS = %i[confirmed_orders confirmed_meals monthly_subsidized_meals company_subsidy_amount].freeze

  def initialize(stats:)
    @stats = stats
  end

  def to_h
    months = @stats.fetch(:trends).fetch(:months)
    raise ArgumentError, "invalid trend length" unless months.size.between?(1, 4)

    period_month = month_string(@stats.fetch(:period).fetch(:month))
    selected = months.last
    raise ArgumentError, "selected trend month mismatch" unless month_string(selected.fetch(:month)) == period_month

    closed = boolean(selected.fetch(:complete))
    orders = @stats.fetch(:orders)
    benefits = @stats.fetch(:benefits)
    employees = @stats.fetch(:employees)
    trusted_roster = !closed && !benefits.fetch(:monthly_quota_meals).nil?
    eligible = integer(employees.fetch(:eligibility).fetch(:eligible)) if trusted_roster

    consumption = {
      confirmed_orders: integer(orders.fetch(:confirmed_orders)),
      confirmed_meals: integer(orders.fetch(:confirmed_meals)),
      monthly_subsidized_meals: integer(benefits.fetch(:monthly_subsidized_meals)),
      confirmed_meals_without_monthly_subsidy: integer(benefits.fetch(:confirmed_meals_without_monthly_subsidy)),
      company_subsidy_amount: money(benefits.fetch(:company_subsidy_amount))
    }
    unless closed
      consumption[:pending] = {
        orders: integer(orders.fetch(:pending_orders)),
        meals: integer(orders.fetch(:pending_meals)),
        monthly_reserved_meals: integer(benefits.fetch(:monthly_pending_reserved_meals))
      }
    end

    anomalies = @stats.fetch(:anomalies)
    raise ArgumentError, "invalid anomaly length" if anomalies.size > 6

    warnings = @stats.fetch(:warnings)
    raise ArgumentError, "invalid warning length" if warnings.size > 26

    {
      schema_version: 1,
      period: { month: period_month, closed: },
      consumption:,
      participation: {
        percent: (percent(employees.fetch(:participation_percent)) if trusted_roster),
        eligible_employees: eligible,
        eligible_without_orders: (integer(employees.fetch(:eligible_without_orders)) if trusted_roster)
      },
      trends: trend_months(months),
      anomalies: anomalies.map { anomaly(it) },
      warnings: warnings.map { warning(it) }
    }
  end

  private

  def trend_months(months)
    months.each_with_index.map do |entry, index|
      previous = months[index - 1] if index.positive?
      trend(entry, previous)
    end
  end

  def trend(entry, previous)
    changes = entry.fetch(:changes)
    comparable = entry.fetch(:complete) == true && previous&.fetch(:complete) == true
    {
      month: month_string(entry.fetch(:month)),
      closed: boolean(entry.fetch(:complete)),
      confirmed_orders: integer(entry.fetch(:confirmed_orders)),
      confirmed_meals: integer(entry.fetch(:confirmed_meals)),
      monthly_subsidized_meals: integer(entry.fetch(:monthly_subsidized_meals)),
      company_subsidy_amount: money(entry.fetch(:company_subsidy_amount)),
      changes: INDICATORS.to_h do |indicator|
        change = changes.fetch(indicator)
        monetary = indicator == :company_subsidy_amount
        convert = monetary ? method(:money) : method(:integer)
        valid_change = comparable && !entry.fetch(indicator).nil? && !change.fetch(:reference).nil?
        [ indicator, {
          reference: convert.call(change.fetch(:reference)),
          difference: (convert.call(change.fetch(:difference)) if valid_change),
          percent: (percent(change.fetch(:percent)) if valid_change)
        } ]
      end
    }
  end

  def anomaly(entry)
    type = entry.fetch(:type)
    indicator = entry.fetch(:indicator)
    raise ArgumentError, "unknown anomaly" unless %w[increase decrease].include?(type) &&
                                                  %w[confirmed_meals monthly_subsidized_meals].include?(indicator)

    {
      type:,
      indicator:,
      month: month_string(entry.fetch(:month)),
      current_value: integer(entry.fetch(:current_value)),
      reference_value: integer(entry.fetch(:reference_value)),
      variation_percent: percent(entry.fetch(:variation_percent))
    }
  end

  def warning(entry)
    code = entry.fetch(:code)
    raise ArgumentError, "unknown warning" unless WARNING_CODES.include?(code)

    result = { code: }
    result[:month] = month_string(entry.fetch(:month)) if code.start_with?("trend_")
    result
  end

  def month_string(value)
    raise ArgumentError, "invalid month" unless value.is_a?(Date)

    value.strftime("%Y-%m")
  end

  def integer(value)
    raise ArgumentError, "invalid count" unless value.nil? || value.is_a?(Integer)

    value
  end

  def boolean(value)
    raise ArgumentError, "invalid boolean" unless value == true || value == false

    value
  end

  def percent(value)
    return if value.nil?
    raise ArgumentError, "invalid percentage" unless value.is_a?(Numeric) && value.finite?

    number = value.to_f
    raise ArgumentError, "invalid percentage" unless number.finite?

    number
  end

  def money(value)
    return if value.nil?
    raise ArgumentError, "invalid amount" unless (value.is_a?(BigDecimal) || value.is_a?(Integer)) && value.finite?

    whole, fraction = value.to_d.round(2).to_s("F").split(".", 2)
    "#{whole}.#{fraction.ljust(2, '0')}"
  end
end
