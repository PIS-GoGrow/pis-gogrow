import type { BenefitUsageStats } from "@/types/benefit-usage"

export function canGenerateBenefitUsageSummary(
  stats: BenefitUsageStats,
): boolean {
  const history = stats.history
  if (!history) return true
  const metrics = history.metrics
  if (history.period.state === "missing_snapshot") {
    return (
      (metrics.confirmed_orders ?? 0) > 0 || (metrics.confirmed_meals ?? 0) > 0
    )
  }
  return [
    metrics.confirmed_orders,
    metrics.confirmed_meals,
    metrics.monthly_quota_meals,
    metrics.eligible_employees,
    metrics.participation_percent,
    metrics.company_subsidy_amount,
  ].some((value) => value !== null && value !== undefined)
}

export function formatBenefitMoney(amount: string): string {
  const match = /^(-?)(\d+)\.(\d{2})$/.exec(amount)
  if (!match) throw new Error("Invalid decimal amount")
  const [, sign, whole, cents] = match
  const grouped = new Intl.NumberFormat("es-UY", {
    useGrouping: "always",
  }).format(BigInt(whole))
  const negative = sign && (BigInt(whole) !== 0n || cents !== "00") ? "-" : ""
  return `${negative}$${grouped},${cents}`
}

export function formatHistoricalBenefitMoney(amount: string): string {
  const match = /^(-?\d+)(?:\.(\d{1,2}))?$/.exec(amount)
  if (!match) throw new Error("Invalid historical decimal amount")
  return formatBenefitMoney(`${match[1]}.${(match[2] ?? "").padEnd(2, "0")}`)
}

export function formatBenefitMonth(month: string): string {
  const [year, number] = month.split("-")
  const date = new Date(0)
  date.setUTCFullYear(Number(year), Number(number) - 1, 1)
  return new Intl.DateTimeFormat("es-UY", {
    month: "long",
    year: "numeric",
    timeZone: "UTC",
  }).format(date)
}
