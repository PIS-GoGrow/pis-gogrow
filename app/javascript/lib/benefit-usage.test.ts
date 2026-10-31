import { describe, expect, it } from "vitest"

import { formatBenefitMoney, formatBenefitMonth } from "./benefit-usage"

describe("benefit usage formatting", () => {
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
  it("formats the period without local timezone shifts", () =>
    expect(formatBenefitMonth("2026-10")).toBe("octubre de 2026"))
})
