# frozen_string_literal: true

class AdminBenefitUsageHistory
  REASON_CODES = %w[
    source_unavailable eligibility_unknown no_eligible_employees no_employees quota_unknown_or_zero
    period_open close_not_verified
  ].freeze
  INDICATORS = %i[
    confirmed_orders confirmed_meals monthly_subsidized_meals monthly_quota_meals
    eligible_with_confirmed_orders participation_percent employees_with_confirmed_orders
    average_confirmed_meals_per_employee company_subsidy_amount
  ].freeze

  def initialize(company:, month:)
    @company = company
    @month = month.beginning_of_month
    @entries = {}
  end

  def to_h
    current = Date.current.beginning_of_month
    oldest = current << 11
    raise ArgumentError, "month outside retention window" unless @month.between?(oldest, current)

    months = 3.downto(0).map { @month << it }.select { it >= oldest }
    series = months.map { entry(it) }
    {
      period: entry(@month).except(:metrics, :unavailable_reasons),
      metrics: entry(@month).fetch(:metrics),
      unavailable_reasons: entry(@month).fetch(:unavailable_reasons),
      trends: series.map { |item| item.slice(:month, :state, :source, :metrics) },
      comparisons: series.each_cons(2).map { |previous, following| compare(previous, following) }
    }
  end

  private

  def entry(month)
    @entries[month] ||= if month == Date.current.beginning_of_month
      current_entry(month)
    elsif (snapshot = @company.benefit_usage_monthly_snapshots.find_by(month:))
      snapshot_entry(snapshot)
    else
      reconstructed_entry(month)
    end
  end

  def current_entry(month)
    stats = AdminBenefitUsageStats.new(company: @company, month:).to_h
    metrics = calculated_metrics(stats)
    {
      month: month.strftime("%Y-%m"), state: "provisional", source: "current_calculation", fictional: false,
      captured_at: nil, calculation_version: nil, metrics:,
      unavailable_reasons: metrics.filter_map { |key, value| [ key, "source_unavailable" ] if value.nil? }.to_h
    }
  end

  def snapshot_entry(snapshot)
    state = snapshot.provisional? ? "incomplete" : snapshot.status
    metrics = {
      employees: snapshot.employees,
      eligible_employees: snapshot.eligible_employees,
      employees_with_confirmed_orders: snapshot.employees_with_confirmed_orders,
      eligible_with_confirmed_orders: snapshot.eligible_with_confirmed_orders,
      eligible_without_orders: snapshot.eligible_without_orders,
      participation_percent: snapshot.participation_percent,
      average_confirmed_meals_per_employee: snapshot.average_confirmed_meals_per_employee,
      monthly_quota_meals: snapshot.monthly_quota_meals,
      monthly_subsidized_meals: snapshot.monthly_subsidized_meals,
      monthly_pending_reserved_meals: snapshot.monthly_pending_reserved_meals,
      monthly_available_meals: snapshot.monthly_available_meals,
      monthly_unused_closed_meals: (snapshot.monthly_unused_closed_meals if state == "closed"),
      confirmed_orders: snapshot.confirmed_orders,
      confirmed_meals: snapshot.confirmed_meals,
      confirmed_meals_without_monthly_subsidy: snapshot.confirmed_meals_without_monthly_subsidy,
      pending_orders: snapshot.pending_orders,
      pending_meals: snapshot.pending_meals,
      company_subsidy_amount: snapshot.company_subsidy_amount
    }
    reasons = snapshot.unavailable_reasons.slice(*metrics.keys.map(&:to_s))
    reasons.transform_values! { |value| REASON_CODES.include?(value) ? value : "source_unavailable" }
    metrics.each { |key, value| reasons[key.to_s] ||= "source_unavailable" if value.nil? }
    reasons["period"] = state == "closed" ? nil : "close_not_verified"
    reasons["monthly_unused_closed_meals"] = "close_not_verified" if state != "closed"
    reasons.compact!
    {
      month: snapshot.month.strftime("%Y-%m"), state:, source: "historical_snapshot", fictional: snapshot.fictional,
      captured_at: snapshot.captured_at.iso8601, calculation_version: snapshot.calculation_version,
      metrics:, unavailable_reasons: reasons
    }
  end

  def reconstructed_entry(month)
    stats = AdminBenefitUsageStats.new(company: @company, month:).to_h
    metrics = calculated_metrics(stats).transform_keys(&:to_sym)
    metrics.slice(:employees, :eligible_employees, :employees_with_confirmed_orders,
                  :eligible_with_confirmed_orders, :eligible_without_orders, :participation_percent,
                  :average_confirmed_meals_per_employee, :monthly_quota_meals, :monthly_pending_reserved_meals,
                  :monthly_available_meals, :monthly_unused_closed_meals, :pending_orders, :pending_meals).each_key do |key|
      metrics[key] = nil
    end
    reasons = metrics.filter_map { |key, value| [ key.to_s, "historical_snapshot_missing" ] if value.nil? }.to_h
    reasons["period"] = "historical_snapshot_missing"
    reasons["reconstructed_orders"] = "retained_records_current_roster"
    {
      month: month.strftime("%Y-%m"), state: "missing_snapshot", source: "historical_reconstruction", fictional: false,
      captured_at: nil, calculation_version: nil, metrics:, unavailable_reasons: reasons
    }
  end

  def calculated_metrics(stats)
    orders = stats.fetch(:orders)
    benefits = stats.fetch(:benefits)
    employees = stats.fetch(:employees)
    count = employees.fetch(:current_employees)
    meals = orders.fetch(:confirmed_meals)
    {
      employees: count, eligible_employees: benefits[:monthly_quota_meals] && employees.dig(:eligibility, :eligible),
      employees_with_confirmed_orders: employees.fetch(:current_employees_with_confirmed_orders),
      eligible_with_confirmed_orders: employees[:known_eligible_with_confirmed_orders],
      eligible_without_orders: employees[:eligible_without_orders], participation_percent: employees[:participation_percent],
      average_confirmed_meals_per_employee: ((meals.to_d / count).round(2) if meals && count.positive?),
      monthly_quota_meals: benefits[:monthly_quota_meals], monthly_subsidized_meals: benefits[:monthly_subsidized_meals],
      monthly_pending_reserved_meals: benefits[:monthly_pending_reserved_meals],
      monthly_available_meals: benefits[:monthly_available_meals], monthly_unused_closed_meals: nil,
      confirmed_orders: orders[:confirmed_orders], confirmed_meals: meals,
      confirmed_meals_without_monthly_subsidy: benefits[:confirmed_meals_without_monthly_subsidy],
      pending_orders: orders[:pending_orders], pending_meals: orders[:pending_meals],
      company_subsidy_amount: benefits[:company_subsidy_amount]
    }
  end

  def compare(previous, following)
    same_source = previous[:source] == "historical_snapshot" && following[:source] == "historical_snapshot"
    same_state = previous[:state] == following[:state] && %w[closed incomplete].include?(following[:state])
    same_version = previous[:calculation_version] == following[:calculation_version]
    same_fictional = previous[:fictional] == following[:fictional]
    same_phase = following[:state] != "incomplete" || (same_source && matching_capture_phase?(previous, following))
    comparable = same_source && same_state && same_version && same_fictional && same_phase
    {
      from: previous[:month], to: following[:month],
      quality: comparable ? (following[:state] == "closed" ? "verified_close" : "capture_only") : "not_comparable",
      changes: INDICATORS.to_h { |indicator| [ indicator, change(previous, following, indicator, comparable:) ] }
    }
  end

  def matching_capture_phase?(previous, following)
    [ previous, following ].all? do |entry|
      captured = Time.iso8601(entry.fetch(:captured_at)).in_time_zone("America/Montevideo")
      captured.to_date == Date.strptime(entry.fetch(:month), "%Y-%m").end_of_month &&
        captured.hour == 23 && captured.min == 55
    end
  end

  def change(previous, following, indicator, comparable:)
    before = previous.dig(:metrics, indicator)
    after = following.dig(:metrics, indicator)
    return { reference: before, current: after, difference: nil, percent: nil, difference_points: nil } unless comparable && before && after

    if indicator == :participation_percent
      previous_eligible = previous.dig(:metrics, :eligible_employees)
      following_eligible = following.dig(:metrics, :eligible_employees)
      previous_participants = previous.dig(:metrics, :eligible_with_confirmed_orders)
      following_participants = following.dig(:metrics, :eligible_with_confirmed_orders)
      return { reference: before, current: after, difference: nil, percent: nil, difference_points: nil } unless
        previous_eligible&.positive? && following_eligible&.positive? && previous_participants && following_participants

      before_exact = previous_participants.to_d * 100 / previous_eligible
      after_exact = following_participants.to_d * 100 / following_eligible
      difference = after_exact - before_exact
    else
      difference = after - before
      before_exact = before
    end
    percent = (difference.to_d * 100 / before_exact).round(2) unless before_exact.zero?
    {
      reference: before, current: after, difference: (difference unless indicator == :participation_percent),
      percent:, difference_points: (difference.round(2) if indicator == :participation_percent)
    }
  end
end
