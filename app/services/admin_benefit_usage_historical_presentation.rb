# frozen_string_literal: true

class AdminBenefitUsageHistoricalPresentation
  def initialize(history:)
    @history = history
  end

  def to_h
    period = @history.fetch(:period)
    metrics = @history.fetch(:metrics)
    verified = period.fetch(:state) == "closed"
    retained_records = period.fetch(:state) == "missing_snapshot"
    display_consumption = verified || retained_records
    {
      schema_version: 1,
      period: { month: period.fetch(:month), closed: true },
      consumption: {
        confirmed_orders: (metrics.fetch(:confirmed_orders) if display_consumption),
        confirmed_meals: (metrics.fetch(:confirmed_meals) if display_consumption),
        monthly_subsidized_meals: (metrics.fetch(:monthly_subsidized_meals) if display_consumption),
        confirmed_meals_without_monthly_subsidy: (metrics.fetch(:confirmed_meals_without_monthly_subsidy) if display_consumption),
        company_subsidy_amount: (money(metrics.fetch(:company_subsidy_amount)) if display_consumption)
      },
      capacity: {
        monthly_quota_meals: (metrics.fetch(:monthly_quota_meals) if verified),
        monthly_pending_reserved_meals: (metrics.fetch(:monthly_pending_reserved_meals) if verified),
        monthly_available_meals: (metrics.fetch(:monthly_available_meals) if verified)
      },
      participation: {
        percent: (metrics.fetch(:participation_percent)&.to_f if verified),
        eligible_employees: (metrics.fetch(:eligible_employees) if verified),
        eligible_without_orders: (metrics.fetch(:eligible_without_orders) if verified)
      },
      employee_activity: {
        current_employees: nil,
        employees_with_confirmed_orders: (metrics.fetch(:employees_with_confirmed_orders) if verified),
        average_confirmed_meals_per_current_employee: nil
      },
      trends: trends,
      anomalies: [],
      warnings: warnings(period),
      history: @history
    }
  end

  private

  def trends
    @history.fetch(:trends).map do |entry|
      month = entry.fetch(:month)
      metrics = entry.fetch(:metrics)
      comparison = @history.fetch(:comparisons).find { it[:to] == month }
      display_consumption = entry.fetch(:state) != "incomplete"
      {
        month:, closed: entry.fetch(:state) == "closed",
        confirmed_orders: (metrics.fetch(:confirmed_orders) if display_consumption),
        confirmed_meals: (metrics.fetch(:confirmed_meals) if display_consumption),
        monthly_subsidized_meals: (metrics.fetch(:monthly_subsidized_meals) if display_consumption),
        company_subsidy_amount: (money(metrics.fetch(:company_subsidy_amount)) if display_consumption),
        changes: %i[confirmed_orders confirmed_meals monthly_subsidized_meals company_subsidy_amount].to_h do |indicator|
          change = comparison&.dig(:changes, indicator)
          trusted = comparison&.dig(:quality) == "verified_close"
          [ indicator, {
            reference: (convert(change[:reference], indicator) if trusted),
            difference: (convert(change[:difference], indicator) if trusted),
            percent: (change[:percent]&.to_f if trusted)
          } ]
        end
      }
    end
  end

  def warnings(period)
    case period.fetch(:state)
    when "incomplete" then [ { code: "historical_status_at_close_unavailable" } ]
    when "missing_snapshot" then [ { code: "historical_roster_incomplete" },
                                     { code: "historical_trends_from_retained_records" } ]
    else []
    end
  end

  def convert(value, indicator)
    indicator == :company_subsidy_amount ? money(value) : value
  end

  def money(value)
    value&.to_d&.to_s("F")
  end
end
