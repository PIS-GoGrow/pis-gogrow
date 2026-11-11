import { describe, expect, it } from "vitest"

import { benefitUsageFixture } from "@/test/benefit-usage-fixture"
import type { BenefitUsageHistory } from "@/types/benefit-usage"

import {
  canGenerateBenefitUsageSummary,
  formatBenefitMoney,
  formatBenefitMonth,
  formatHistoricalBenefitMoney,
} from "./benefit-usage"

describe("benefit usage formatting", () => {
  it("permits useful historical data and blocks unknown or empty reconstruction", () => {
    const stats = benefitUsageFixture()
    expect(canGenerateBenefitUsageSummary(stats)).toBe(true)
    stats.history = {
      period: { state: "incomplete" },
      metrics: {
        confirmed_orders: 0,
        confirmed_meals: 0,
        monthly_quota_meals: null,
        eligible_employees: null,
        participation_percent: null,
        company_subsidy_amount: null,
      },
    } as BenefitUsageHistory
    expect(canGenerateBenefitUsageSummary(stats)).toBe(true)
    stats.history.metrics.confirmed_orders = null
    stats.history.metrics.confirmed_meals = null
    expect(canGenerateBenefitUsageSummary(stats)).toBe(false)
    stats.history.metrics.confirmed_meals = 0
    stats.history.period.state = "missing_snapshot"
    expect(canGenerateBenefitUsageSummary(stats)).toBe(false)
    stats.history.metrics.confirmed_meals = 2
    expect(canGenerateBenefitUsageSummary(stats)).toBe(true)
  })
  it.each([
    ["0.00", "$0,00"],
    ["1250.00", "$1.250,00"],
    ["125000.00", "$125.000,00"],
    ["1250.50", "$1.250,50"],
    ["9007199254740993.01", "$9.007.199.254.740.993,01"],
    ["-1234.05", "-$1.234,05"],
    ["-0.00", "$0,00"],
  ])("formats %s exactly", (input, expected) =>
    expect(formatBenefitMoney(input)).toBe(expected),
  )
  it("does not disguise invalid values as zero", () =>
    expect(() => formatBenefitMoney("invalid")).toThrow())
  it("formats historical decimal JSON without losing cents", () => {
    expect(formatHistoricalBenefitMoney("6600.0")).toBe("$6.600,00")
    expect(formatHistoricalBenefitMoney("2400.0")).toBe("$2.400,00")
    expect(formatHistoricalBenefitMoney("9007199254740993.01")).toBe(
      "$9.007.199.254.740.993,01",
    )
  })
  it("formats the period without local timezone shifts", () =>
    expect(formatBenefitMonth("2026-10")).toBe("octubre de 2026"))
})
