# frozen_string_literal: true

require Rails.root.join("lib/ibp041/fictional_snapshot_scenarios")

module BenefitUsageSnapshotScenarios
  def ibp_041_2026_snapshots(company:)
    raise "historical scenarios require the test environment" unless Rails.env.test?

    Ibp041::FictionalSnapshotScenarios.months.map do |key|
      historical_snapshot(company:, month: Date.iso8601("#{key}-01"),
                          **Ibp041::FictionalSnapshotScenarios.attributes(key))
    end
  end

  def ibp_041_incomplete_snapshot(company:, key: "2026-09")
    raise "historical scenarios require the test environment" unless Rails.env.test?

    historical_snapshot(company:, month: Date.iso8601("#{key}-01"),
                        **Ibp041::FictionalSnapshotScenarios.attributes(key).merge(
                          status: :incomplete, closed_at: nil, monthly_unused_closed_meals: nil,
                          unavailable_reasons: { "period" => "close_not_verified",
                                                 "monthly_unused_closed_meals" => "close_not_verified" }
                        ))
  end

  def ibp_041_verified_close(company:)
    raise "historical scenarios require the test environment" unless Rails.env.test?

    historical_snapshot(company:, month: Date.new(2026, 8, 1), employees: 35, eligible_employees: 33,
                        employees_with_confirmed_orders: 10, eligible_with_confirmed_orders: 10,
                        eligible_without_orders: 23, monthly_quota_meals: 660,
                        confirmed_orders: 15, confirmed_meals: 20, monthly_subsidized_meals: 20,
                        monthly_available_meals: 640, monthly_unused_closed_meals: 640,
                        company_subsidy_amount: BigDecimal("3000.00"))
  end

  def historical_snapshot(company:, month:, **attributes)
    raise "historical scenarios require the test environment" unless Rails.env.test?

    BenefitUsageMonthlySnapshot.create!({
      company:, month: month.beginning_of_month, status: :closed, closed_at: month.next_month.beginning_of_month,
      captured_at: month.end_of_month.end_of_day, fictional: true,
      employees: 10, eligible_employees: 8, unknown_eligibility_employees: 0,
      employees_with_confirmed_orders: 4, eligible_with_confirmed_orders: 4, eligible_without_orders: 4,
      monthly_quota_meals: 160, monthly_subsidized_meals: 40,
      monthly_pending_reserved_meals: 0, monthly_available_meals: 120, monthly_unused_closed_meals: 120,
      confirmed_orders: 20, confirmed_meals: 40, confirmed_meals_without_monthly_subsidy: 0,
      pending_orders: 0, pending_meals: 0, company_subsidy_amount: 4000,
      unavailable_reasons: {}
    }.merge(attributes))
  end
end

RSpec.configure { |config| config.include BenefitUsageSnapshotScenarios }
