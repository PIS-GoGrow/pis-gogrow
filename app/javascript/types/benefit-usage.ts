export interface BenefitUsageIndicators {
  confirmed_orders: number | null
  confirmed_meals: number | null
  monthly_subsidized_meals: number | null
  company_subsidy_amount: string | null
}

export interface BenefitUsageChange<T> {
  reference: T | null
  difference: T | null
  percent: number | null
}

export interface BenefitUsageTrend extends BenefitUsageIndicators {
  month: string
  closed: boolean
  changes: {
    confirmed_orders: BenefitUsageChange<number>
    confirmed_meals: BenefitUsageChange<number>
    monthly_subsidized_meals: BenefitUsageChange<number>
    company_subsidy_amount: BenefitUsageChange<string>
  }
}

export interface BenefitUsageHistoryMetrics {
  employees: number | null
  eligible_employees: number | null
  employees_with_confirmed_orders: number | null
  eligible_with_confirmed_orders: number | null
  eligible_without_orders: number | null
  participation_percent: number | string | null
  average_confirmed_meals_per_employee: number | string | null
  monthly_quota_meals: number | null
  monthly_subsidized_meals: number | null
  monthly_pending_reserved_meals: number | null
  monthly_available_meals: number | null
  monthly_unused_closed_meals: number | null
  confirmed_orders: number | null
  confirmed_meals: number | null
  confirmed_meals_without_monthly_subsidy: number | null
  pending_orders: number | null
  pending_meals: number | null
  company_subsidy_amount: string | null
}

export interface BenefitUsageHistory {
  period: {
    month: string
    state: "provisional" | "closed" | "incomplete" | "missing_snapshot"
    source:
      | "current_calculation"
      | "historical_snapshot"
      | "historical_reconstruction"
    fictional: boolean
    captured_at: string | null
    calculation_version: number | null
  }
  metrics: BenefitUsageHistoryMetrics
  unavailable_reasons: Record<string, string>
  trends: {
    month: string
    state: BenefitUsageHistory["period"]["state"]
    source: BenefitUsageHistory["period"]["source"]
    metrics: BenefitUsageHistoryMetrics
  }[]
  comparisons: {
    from: string
    to: string
    quality: "verified_close" | "capture_only" | "not_comparable"
    changes: Record<
      string,
      {
        reference: number | string | null
        current: number | string | null
        difference: number | string | null
        percent: number | string | null
        difference_points: number | string | null
      }
    >
  }[]
}

export interface BenefitUsageStats {
  schema_version: 1
  analysis_revision: string
  period: { month: string; closed: boolean }
  history?: BenefitUsageHistory
  consumption: BenefitUsageIndicators & {
    confirmed_meals_without_monthly_subsidy: number | null
    pending?: {
      orders: number | null
      meals: number | null
      monthly_reserved_meals: number | null
    }
  }
  capacity: {
    monthly_quota_meals: number | null
    monthly_pending_reserved_meals: number | null
    monthly_available_meals: number | null
  }
  participation: {
    percent: number | null
    eligible_employees: number | null
    eligible_without_orders: number | null
  }
  employee_activity: {
    current_employees: number | null
    employees_with_confirmed_orders: number | null
    average_confirmed_meals_per_current_employee: number | null
  }
  trends: BenefitUsageTrend[]
  anomalies: {
    type: "increase" | "decrease"
    indicator: "confirmed_meals" | "monthly_subsidized_meals"
    month: string
    current_value: number | null
    reference_value: number | null
    variation_percent: number | null
  }[]
  warnings: { code: string; month?: string }[]
}

export interface BenefitUsageSummary {
  success: true
  text: string
  month: string
  generated_at: string
  generated_at_label: string
  generated_by_ai: true
}
