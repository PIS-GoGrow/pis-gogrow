import type { BenefitUsageStats } from "@/types/benefit-usage"

export function benefitUsageFixture(month = "2026-10"): BenefitUsageStats {
  const change = { reference: null, difference: null, percent: null }
  return {
    schema_version: 1,
    period: { month, closed: false },
    consumption: {
      confirmed_orders: 12,
      confirmed_meals: 45,
      monthly_subsidized_meals: 40,
      confirmed_meals_without_monthly_subsidy: 5,
      company_subsidy_amount: "5425.25",
      pending: { orders: 2, meals: 3, monthly_reserved_meals: 3 },
    },
    capacity: {
      monthly_quota_meals: 300,
      monthly_pending_reserved_meals: 3,
      monthly_available_meals: 257,
    },
    participation: {
      percent: 72,
      eligible_employees: 25,
      eligible_without_orders: 7,
    },
    trends: ["2026-06", "2026-07", "2026-08", month].map((key, index) => ({
      month: key,
      closed: index < 3,
      confirmed_orders: 12,
      confirmed_meals: index === 1 ? null : 45,
      monthly_subsidized_meals: 40,
      company_subsidy_amount: "5425.25",
      changes: {
        confirmed_orders: change,
        confirmed_meals: change,
        monthly_subsidized_meals: change,
        company_subsidy_amount: change,
      },
    })),
    anomalies: [],
    warnings: [{ code: "open_month_partial" }],
  }
}
