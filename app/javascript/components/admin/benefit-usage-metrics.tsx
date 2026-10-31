import type { ReactNode } from "react"
import { useTranslation } from "react-i18next"

import BenefitUsageCollapsibleCard from "@/components/admin/benefit-usage-collapsible-card"
import HeadingSmall from "@/components/heading-small"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible"
import { Progress } from "@/components/ui/progress"
import { formatBenefitMoney, formatBenefitMonth } from "@/lib/benefit-usage"
import { cn } from "@/lib/utils"
import type { BenefitUsageStats } from "@/types/benefit-usage"

interface BenefitUsageMetricsProps {
  stats: BenefitUsageStats
}

export default function BenefitUsageMetrics({
  stats,
}: BenefitUsageMetricsProps) {
  const { t } = useTranslation()
  const p = "benefit_usage.ui"
  const unknown = t(`${p}.unavailable`)
  const count = (value: number | null) =>
    value === null ? unknown : value.toLocaleString("es-UY")
  const percent = (value: number | null) =>
    value === null
      ? unknown
      : `${value.toLocaleString("es-UY", { maximumFractionDigits: 2 })}%`
  const decimal = (value: number | null) =>
    value === null
      ? unknown
      : value.toLocaleString("es-UY", { maximumFractionDigits: 2 })
  const money = (value: string | null) =>
    value === null ? unknown : formatBenefitMoney(value)
  const { consumption, capacity, participation, employee_activity } = stats
  const available = capacity.monthly_available_meals
  const quota = capacity.monthly_quota_meals
  const usedMeals =
    available !== null && quota !== null ? quota - available : null
  const usedPercentage =
    usedMeals !== null &&
    quota !== null &&
    quota > 0 &&
    capacity.monthly_pending_reserved_meals !== null
      ? Math.min(100, Math.max(0, (usedMeals / quota) * 100))
      : null
  const historicalWarningCounts = stats.warnings.reduce<Record<string, number>>(
    (counts, warning) => {
      if (warning.month) counts[warning.code] = (counts[warning.code] ?? 0) + 1
      return counts
    },
    {},
  )
  const groupedHistoricalWarningCodes = Object.entries(historicalWarningCounts)
    .filter(([, warningCount]) => warningCount > 1)
    .map(([code]) => code)
  const specificWarnings = stats.warnings.filter(
    (warning) =>
      !warning.month || !groupedHistoricalWarningCodes.includes(warning.code),
  )
  const maxMeals = Math.max(
    1,
    ...stats.trends.flatMap((entry) =>
      entry.confirmed_meals === null ? [] : [entry.confirmed_meals],
    ),
  )

  return (
    <>
      <BenefitUsageCollapsibleCard
        title={t(`${p}.consumption`)}
        defaultOpen
        accessory={
          <Badge variant="secondary">
            {t(`${p}.${stats.period.closed ? "closed" : "open"}`)}
          </Badge>
        }
        contentClassName="space-y-4"
      >
        <dl className="grid grid-cols-2 gap-4">
          <Metric
            label={t(`${p}.indicators.confirmed_meals`)}
            value={count(consumption.confirmed_meals)}
            prominent
          />
          <Metric
            label={t(`${p}.indicators.confirmed_orders`)}
            value={count(consumption.confirmed_orders)}
            prominent
          />
        </dl>
        {consumption.confirmed_orders === 0 && (
          <p className="text-muted-foreground text-sm">{t(`${p}.empty`)}</p>
        )}
        <dl className="bg-background divide-border grid divide-y rounded-lg border px-4 [&>div]:py-3">
          <Metric
            label={t(`${p}.indicators.monthly_subsidized_meals`)}
            value={count(consumption.monthly_subsidized_meals)}
            compact
          />
          <Metric
            label={t(`${p}.without_subsidy`)}
            value={count(consumption.confirmed_meals_without_monthly_subsidy)}
            compact
          />
          <Metric
            label={t(`${p}.indicators.company_subsidy_amount`)}
            value={money(consumption.company_subsidy_amount)}
            compact
            monetary
          />
        </dl>
        <Collapsible>
          <CollapsibleTrigger asChild>
            <Button variant="link" size="sm" className="h-auto p-0">
              {t(`${p}.subsidy_explanation`)}
            </Button>
          </CollapsibleTrigger>
          <CollapsibleContent className="pt-2">
            <p className="text-muted-foreground text-sm">
              {t(`${p}.subsidy_note`)}
            </p>
          </CollapsibleContent>
        </Collapsible>
        {consumption.pending && (
          <p className="text-muted-foreground text-sm">
            {t(`${p}.pending`, {
              orders: t(`${p}.pending_orders`, {
                count: consumption.pending.orders,
              }),
              meals: t(`${p}.pending_meals`, {
                count: consumption.pending.meals,
              }),
            })}
          </p>
        )}
      </BenefitUsageCollapsibleCard>

      <div
        className={cn("grid gap-4", !stats.period.closed && "lg:grid-cols-2")}
      >
        {!stats.period.closed && (
          <BenefitUsageCollapsibleCard title={t(`${p}.capacity`)}>
            <dl className="bg-background divide-border grid divide-y rounded-lg border px-4 [&>div]:py-4">
              <Metric
                label={t(`${p}.available`)}
                value={count(available)}
                prominent
              />
              <Metric label={t(`${p}.quota`)} value={count(quota)} />
              <Metric
                label={t(`${p}.reserved`)}
                value={count(capacity.monthly_pending_reserved_meals)}
              />
            </dl>
            {usedPercentage !== null && usedMeals !== null && (
              <div className="space-y-2">
                <Progress
                  value={usedPercentage}
                  aria-label={t(`${p}.used_capacity`)}
                  aria-valuenow={usedPercentage}
                  aria-valuetext={t(`${p}.used_of`, {
                    used: count(usedMeals),
                    quota: count(quota),
                  })}
                />
                <p className="text-muted-foreground text-sm font-medium">
                  {t(`${p}.used_of`, {
                    used: count(usedMeals),
                    quota: count(quota),
                  })}
                </p>
              </div>
            )}
            <p className="text-muted-foreground text-sm">
              {t(
                `${p}.${usedPercentage === null ? "unknown_capacity" : "capacity_note"}`,
              )}
            </p>
          </BenefitUsageCollapsibleCard>
        )}
        <BenefitUsageCollapsibleCard
          title={t(
            `${p}.${stats.period.closed ? "employee_activity" : "participation"}`,
          )}
        >
          <dl className="bg-background divide-border grid divide-y rounded-lg border px-4 [&>div]:py-4">
            {stats.period.closed ? (
              <>
                <Metric
                  label={t(`${p}.employees_with_confirmed_orders`)}
                  value={count(
                    employee_activity.employees_with_confirmed_orders,
                  )}
                  prominent
                />
                <Metric
                  label={t(`${p}.current_employees`)}
                  value={count(employee_activity.current_employees)}
                />
                <Metric
                  label={t(`${p}.historical_average`)}
                  value={decimal(
                    employee_activity.average_confirmed_meals_per_current_employee,
                  )}
                />
              </>
            ) : (
              <>
                <Metric
                  label={t(`${p}.participation_percent`)}
                  value={percent(participation.percent)}
                  prominent
                />
                <Metric
                  label={t(`${p}.employees`)}
                  value={count(employee_activity.current_employees)}
                />
                <Metric
                  label={t(`${p}.average_per_employee`)}
                  value={decimal(
                    employee_activity.average_confirmed_meals_per_current_employee,
                  )}
                />
              </>
            )}
          </dl>
          {!stats.period.closed && (
            <p className="text-muted-foreground text-sm">
              {t(`${p}.participation_note`)}
            </p>
          )}
          <p className="text-muted-foreground text-sm">
            {t(
              `${p}.${stats.period.closed ? "historical_average_note" : "average_note"}`,
            )}
          </p>
        </BenefitUsageCollapsibleCard>
      </div>

      <BenefitUsageCollapsibleCard title={t(`${p}.trends`)}>
        <p className="text-muted-foreground text-sm">{t(`${p}.trends_note`)}</p>
        <ul
          className="space-y-4"
          aria-label={t(`${p}.indicators.confirmed_meals`)}
        >
          {stats.trends.map((entry) => (
            <li
              key={entry.month}
              className="bg-background space-y-3 rounded-lg border p-4"
            >
              <div className="flex flex-wrap items-center justify-between gap-2 text-sm">
                <span>
                  {formatBenefitMonth(entry.month)}{" "}
                  {!entry.closed && (
                    <Badge variant="outline">{t(`${p}.open`)}</Badge>
                  )}
                </span>
                <span className="font-semibold">
                  {count(entry.confirmed_meals)}
                </span>
              </div>
              {entry.confirmed_meals !== null && (
                <div
                  aria-hidden="true"
                  className="bg-muted h-2 overflow-hidden rounded-full"
                >
                  <div
                    className={
                      entry.closed
                        ? "bg-foreground h-full rounded-full"
                        : "bg-muted-foreground h-full rounded-full"
                    }
                    style={{
                      width: `${(entry.confirmed_meals / maxMeals) * 100}%`,
                    }}
                  />
                </div>
              )}
              <p className="text-muted-foreground text-xs">
                {entry.changes.confirmed_meals.percent === null
                  ? t(`${p}.not_comparable`)
                  : t(`${p}.variation`, {
                      percent: percent(entry.changes.confirmed_meals.percent),
                    })}
              </p>
            </li>
          ))}
        </ul>
        <Collapsible>
          <CollapsibleTrigger asChild>
            <Button variant="ghost" size="sm">
              {t(`${p}.trend_details`)}
            </Button>
          </CollapsibleTrigger>
          <CollapsibleContent className="space-y-4 pt-4">
            {stats.trends.map((entry) => (
              <section
                key={entry.month}
                aria-label={formatBenefitMonth(entry.month)}
                className="space-y-3 border-t pt-4"
              >
                <HeadingSmall title={formatBenefitMonth(entry.month)} />
                <dl className="grid gap-4 sm:grid-cols-2">
                  {(
                    [
                      "confirmed_orders",
                      "confirmed_meals",
                      "monthly_subsidized_meals",
                      "company_subsidy_amount",
                    ] as const
                  ).map((indicator) => {
                    const monetary = indicator === "company_subsidy_amount"
                    const change = entry.changes[indicator]
                    const format = (value: number | string | null) =>
                      value === null
                        ? unknown
                        : monetary
                          ? money(value as string)
                          : count(value as number)
                    return (
                      <div key={indicator}>
                        <Metric
                          label={t(`${p}.indicators.${indicator}`)}
                          value={format(entry[indicator])}
                        />
                        <p className="text-muted-foreground mt-1 text-xs">
                          {t(`${p}.change_detail`, {
                            reference: format(change.reference),
                            difference: format(change.difference),
                            percent: percent(change.percent),
                          })}
                        </p>
                      </div>
                    )
                  })}
                </dl>
              </section>
            ))}
          </CollapsibleContent>
        </Collapsible>
      </BenefitUsageCollapsibleCard>

      {stats.warnings.length > 0 && (
        <BenefitUsageCollapsibleCard title={t(`${p}.warnings_title`)}>
          {groupedHistoricalWarningCodes.length > 0 && (
            <section className="space-y-2">
              <HeadingSmall title={t(`${p}.historical_limitations`)} />
              <p className="text-muted-foreground text-sm">
                {t(`${p}.historical_warnings_grouped`)}
              </p>
              <ul className="text-muted-foreground list-disc space-y-2 pl-4 text-sm">
                {groupedHistoricalWarningCodes.map((code) => (
                  <li key={code}>
                    {t(`${p}.warnings.${code}`, {
                      defaultValue: t(`${p}.warning_fallback`),
                    })}
                  </li>
                ))}
              </ul>
            </section>
          )}
          {specificWarnings.length > 0 && (
            <section className="space-y-2">
              {groupedHistoricalWarningCodes.length > 0 && (
                <HeadingSmall title={t(`${p}.specific_limitations`)} />
              )}
              <ul className="text-muted-foreground list-disc space-y-2 pl-4 text-sm">
                {specificWarnings.map((warning, index) => (
                  <li key={`${warning.code}-${warning.month ?? index}`}>
                    {warning.month && `${formatBenefitMonth(warning.month)}: `}
                    {t(`${p}.warnings.${warning.code}`, {
                      defaultValue: t(`${p}.warning_fallback`),
                    })}
                  </li>
                ))}
              </ul>
            </section>
          )}
        </BenefitUsageCollapsibleCard>
      )}
    </>
  )
}

function Metric({
  label,
  value,
  prominent = false,
  compact = false,
  monetary = false,
}: {
  label: string
  value: ReactNode
  prominent?: boolean
  compact?: boolean
  monetary?: boolean
}) {
  const stackAmount = monetary && typeof value === "string" && value.length > 15

  return (
    <div
      className={
        monetary
          ? stackAmount
            ? "grid grid-cols-1 gap-1"
            : "grid grid-cols-[minmax(0,1fr)_auto] items-start gap-4"
          : compact
            ? "flex items-start justify-between gap-4"
            : undefined
      }
    >
      <dt className="text-muted-foreground min-w-0 text-sm">{label}</dt>
      <dd
        className={
          monetary
            ? "max-w-full overflow-x-auto text-right text-base font-semibold whitespace-nowrap tabular-nums"
            : compact
              ? "min-w-0 text-right text-base font-semibold break-words"
              : prominent
                ? "mt-1 text-2xl font-semibold tracking-tight break-words"
                : "mt-1 text-lg font-semibold break-words"
        }
      >
        {value}
      </dd>
    </div>
  )
}
