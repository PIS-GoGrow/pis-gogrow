import { ChevronDown } from "lucide-react"
import type { ReactNode } from "react"
import { useTranslation } from "react-i18next"

import HeadingSmall from "@/components/heading-small"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible"
import { Progress } from "@/components/ui/progress"
import { formatBenefitMoney, formatBenefitMonth } from "@/lib/benefit-usage"
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
  const money = (value: string | null) =>
    value === null ? unknown : formatBenefitMoney(value)
  const { consumption, capacity, participation } = stats
  const available = capacity.monthly_available_meals
  const quota = capacity.monthly_quota_meals
  const availability =
    available !== null && quota !== null && quota > 0
      ? (available / quota) * 100
      : null
  const maxMeals = Math.max(
    1,
    ...stats.trends.flatMap((entry) =>
      entry.confirmed_meals === null ? [] : [entry.confirmed_meals],
    ),
  )

  return (
    <>
      <Card className="bg-muted gap-4 rounded-lg py-5 shadow-none">
        <CardHeader className="flex flex-row flex-wrap items-center justify-between gap-3 px-5 sm:px-6">
          <CardTitle>
            <h3>{t(`${p}.consumption`)}</h3>
          </CardTitle>
          <Badge variant="secondary">
            {t(`${p}.${stats.period.closed ? "closed" : "open"}`)}
          </Badge>
        </CardHeader>
        <CardContent className="space-y-4 px-5 sm:px-6">
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
        </CardContent>
      </Card>

      <div className="grid gap-4 lg:grid-cols-2">
        <Panel title={t(`${p}.capacity`)}>
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
          {availability !== null && (
            <Progress
              value={availability}
              aria-label={t(`${p}.available`)}
              aria-valuenow={availability}
              aria-valuetext={t(`${p}.available_of`, {
                available: count(available),
                quota: count(quota),
              })}
            />
          )}
          <p className="text-muted-foreground text-sm">
            {t(
              `${p}.${stats.period.closed ? "historical_capacity" : available === null || quota === null || capacity.monthly_pending_reserved_meals === null ? "unknown_capacity" : "capacity_note"}`,
            )}
          </p>
        </Panel>
        <Panel title={t(`${p}.participation`)}>
          <dl className="bg-background divide-border grid divide-y rounded-lg border px-4 [&>div]:py-4">
            <Metric
              label={t(`${p}.participation_percent`)}
              value={percent(participation.percent)}
              prominent
            />
            <Metric
              label={t(`${p}.eligible`)}
              value={count(participation.eligible_employees)}
            />
            <Metric
              label={t(`${p}.without_orders`)}
              value={count(participation.eligible_without_orders)}
            />
          </dl>
          <p className="text-muted-foreground text-sm">
            {t(
              `${p}.${participation.percent === null ? "unknown_participation" : "participation_note"}`,
            )}
          </p>
        </Panel>
      </div>

      <Panel title={t(`${p}.trends`)}>
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
      </Panel>

      {stats.warnings.length > 0 && (
        <Collapsible className="bg-muted rounded-lg border">
          <CollapsibleTrigger asChild>
            <Button
              variant="ghost"
              className="group h-auto w-full justify-between px-5 py-4 text-left"
            >
              {t(`${p}.warnings_title`)}
              <ChevronDown
                aria-hidden="true"
                className="transition-transform group-data-[state=open]:rotate-180"
              />
            </Button>
          </CollapsibleTrigger>
          <CollapsibleContent className="px-5 pb-5">
            <ul className="text-muted-foreground list-disc space-y-2 pl-4 text-sm">
              {stats.warnings.map((warning, index) => (
                <li key={`${warning.code}-${warning.month ?? index}`}>
                  {warning.month && `${formatBenefitMonth(warning.month)}: `}
                  {t(`${p}.warnings.${warning.code}`, {
                    defaultValue: t(`${p}.warning_fallback`),
                  })}
                </li>
              ))}
            </ul>
          </CollapsibleContent>
        </Collapsible>
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

function Panel({ title, children }: { title: string; children: ReactNode }) {
  return (
    <Card className="bg-muted gap-6 rounded-lg py-6 shadow-none">
      <CardHeader className="px-5 sm:px-6">
        <CardTitle>
          <h3>{title}</h3>
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-6 px-5 sm:px-6">{children}</CardContent>
    </Card>
  )
}
