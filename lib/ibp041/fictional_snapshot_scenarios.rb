# frozen_string_literal: true

module Ibp041
  module FictionalSnapshotScenarios
    DATA = {
      "2026-09" => {
        employees: 38, eligible_employees: 36, unknown_eligibility_employees: 0,
        employees_with_confirmed_orders: 12, eligible_with_confirmed_orders: 12, eligible_without_orders: 24,
        monthly_quota_meals: 720, confirmed_orders: 20, confirmed_meals: 28,
        monthly_subsidized_meals: 28, confirmed_meals_without_monthly_subsidy: 0,
        pending_orders: 2, pending_meals: 2, monthly_pending_reserved_meals: 2,
        monthly_available_meals: 690, monthly_unused_closed_meals: nil,
        company_subsidy_amount: "4200.00"
      },
      "2026-10" => {
        employees: 40, eligible_employees: 38, unknown_eligibility_employees: 0,
        employees_with_confirmed_orders: 16, eligible_with_confirmed_orders: 16, eligible_without_orders: 22,
        monthly_quota_meals: 760, confirmed_orders: 30, confirmed_meals: 44,
        monthly_subsidized_meals: 40, confirmed_meals_without_monthly_subsidy: 4,
        pending_orders: 3, pending_meals: 4, monthly_pending_reserved_meals: 4,
        monthly_available_meals: 716, monthly_unused_closed_meals: nil,
        company_subsidy_amount: "6600.00"
      }
    }.freeze

    def self.months
      DATA.keys
    end

    def self.attributes(key)
      month = Date.iso8601("#{key}-01")
      DATA.fetch(key).merge(
        status: :incomplete,
        closed_at: nil,
        captured_at: Time.zone.local(month.year, month.month, month.end_of_month.day, 23, 55),
        unavailable_reasons: {
          "period" => "close_not_verified",
          "monthly_unused_closed_meals" => "close_not_verified"
        }
      )
    end
  end
end
