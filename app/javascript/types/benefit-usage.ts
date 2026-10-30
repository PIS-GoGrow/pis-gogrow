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

export interface BenefitUsageStats {
  schema_version: 1
  period: { month: string; closed: boolean }
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
    current_employees: number
    employees_with_confirmed_orders: number
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
