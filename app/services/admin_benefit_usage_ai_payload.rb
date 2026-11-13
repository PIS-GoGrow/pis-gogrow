# frozen_string_literal: true

class AdminBenefitUsageAiPayload
  class InsufficientData < StandardError; end

  HISTORICAL_COUNTS = %i[
    employees eligible_employees employees_with_confirmed_orders eligible_with_confirmed_orders
    monthly_quota_meals monthly_subsidized_meals monthly_pending_reserved_meals monthly_available_meals
    monthly_unused_closed_meals confirmed_orders confirmed_meals confirmed_meals_without_monthly_subsidy
  ].freeze
  HISTORICAL_DECIMALS = %i[participation_percent average_confirmed_meals_per_employee].freeze
  HISTORICAL_CHANGES = %i[
    confirmed_meals monthly_subsidized_meals monthly_quota_meals eligible_with_confirmed_orders
    participation_percent company_subsidy_amount
  ].freeze
  HISTORICAL_REASONS = %w[
    source_unavailable eligibility_unknown no_eligible_employees no_employees quota_unknown_or_zero
    period_open close_not_verified historical_snapshot_missing retained_records_current_roster
  ].freeze
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

  def initialize(stats: nil, history: nil)
    @stats = stats
    @history = history
  end

  def to_h
    return historical_payload if @history

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
    eligible_with_confirmed = integer(employees.fetch(:known_eligible_with_confirmed_orders)) if trusted_roster

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
      capacity: {
        monthly_quota_meals: (integer(benefits.fetch(:monthly_quota_meals)) unless closed),
        monthly_pending_reserved_meals: (integer(benefits.fetch(:monthly_pending_reserved_meals)) unless closed),
        monthly_available_meals: (integer(benefits.fetch(:monthly_available_meals)) unless closed)
      },
      participation: {
        percent: (percent(employees.fetch(:participation_percent)) if trusted_roster),
        eligible_employees: eligible,
        eligible_with_confirmed_orders: eligible_with_confirmed,
        eligible_without_confirmed_orders: (eligible - eligible_with_confirmed if eligible && eligible_with_confirmed),
        eligible_without_orders: (integer(employees.fetch(:eligible_without_orders)) if trusted_roster)
      },
      trends: trend_months(months),
      anomalies: anomalies.map { anomaly(it) },
      warnings: warnings.map { warning(it) }
    }
  end

  private

  def historical_payload
    period = @history.fetch(:period)
    month = period.fetch(:month)
    state = period.fetch(:state)
    source = period.fetch(:source)
    raise ArgumentError, "invalid historical period" unless month.is_a?(String) && month.match?(/\A\d{4}-(?:0[1-9]|1[0-2])\z/) &&
                                                      { "closed" => "historical_snapshot", "incomplete" => "historical_snapshot",
                                                        "missing_snapshot" => "historical_reconstruction" }[state] == source

    captured_at = period.fetch(:captured_at)
    captured_at = Time.iso8601(captured_at).iso8601 if captured_at
    raise ArgumentError, "invalid capture time" if (source == "historical_snapshot") != captured_at.present?

    source_metrics = @history.fetch(:metrics)
    metrics = HISTORICAL_COUNTS.to_h { |key| [ key, integer(source_metrics.fetch(key)) ] }
    HISTORICAL_DECIMALS.each { |key| metrics[key] = percent(source_metrics.fetch(key)) }
    metrics[:company_subsidy_amount] = money(source_metrics.fetch(:company_subsidy_amount))
    metrics[:monthly_unused_closed_meals] = nil unless state == "closed"

    enough = if state == "missing_snapshot"
      metrics[:confirmed_orders].to_i.positive? || metrics[:confirmed_meals].to_i.positive?
    else
      %i[confirmed_orders confirmed_meals monthly_quota_meals eligible_employees participation_percent
         company_subsidy_amount].any? { |key| !metrics[key].nil? }
    end
    raise InsufficientData unless enough

    reasons = @history.fetch(:unavailable_reasons)
    allowed_indicators = HISTORICAL_COUNTS + HISTORICAL_DECIMALS + %i[company_subsidy_amount period reconstructed_orders]
    limitations = reasons.filter_map do |key, reason|
      next unless allowed_indicators.include?(key.to_sym)

      { indicator: key.to_s, reason: HISTORICAL_REASONS.include?(reason) ? reason : "source_unavailable" }
    end

    {
      schema_version: 2,
      period: { month:, state:, source:, captured_at: },
      metrics:,
      comparison: historical_comparison(month, state),
      limitations:
    }
  end

  def historical_comparison(month, state)
    item = @history.fetch(:comparisons).find { it.fetch(:to) == month }
    return unless item && item.fetch(:quality) == { "closed" => "verified_close", "incomplete" => "capture_only" }[state]

    changes = item.fetch(:changes)
    {
      from: item.fetch(:from), to: month, quality: item.fetch(:quality),
      changes: HISTORICAL_CHANGES.to_h do |key|
        change = changes.fetch(key)
        convert = key == :company_subsidy_amount ? method(:money) :
                  (key == :participation_percent ? method(:percent) : method(:integer))
        [ key, {
          reference: convert.call(change.fetch(:reference)), current: convert.call(change.fetch(:current)),
          difference: (convert.call(change.fetch(:difference)) unless key == :participation_percent),
          percent: percent(change.fetch(:percent)),
          difference_points: (percent(change.fetch(:difference_points)) if key == :participation_percent)
        } ]
      end
    }
  end

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
