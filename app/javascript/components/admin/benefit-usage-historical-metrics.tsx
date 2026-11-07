import { useTranslation } from "react-i18next"

import BenefitUsageCollapsibleCard from "@/components/admin/benefit-usage-collapsible-card"
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { Badge } from "@/components/ui/badge"
import {
  formatBenefitMonth,
  formatHistoricalBenefitMoney,
} from "@/lib/benefit-usage"
import type { BenefitUsageHistory } from "@/types/benefit-usage"

const p = "benefit_usage.ui.history"

function capturedAt(value: string) {
  const parts = new Intl.DateTimeFormat("es-UY", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
    timeZone: "America/Montevideo",
  }).formatToParts(new Date(value))
  const date = Object.fromEntries(parts.map(({ type, value }) => [type, value]))
  return `${date.day}/${date.month}/${date.year} · ${date.hour}:${date.minute}`
}

export default function BenefitUsageHistoricalMetrics({
  history,
}: {
  history: BenefitUsageHistory
}) {
  const { t } = useTranslation()
  const { metrics, period } = history
  const missingSnapshot = period.state === "missing_snapshot"
  const unknown = t(`${p}.unknown`)
  const number = (value: number | string | null) =>
    value === null
      ? unknown
      : Number(value).toLocaleString("es-UY", { maximumFractionDigits: 2 })
  const money = (value: string | null) =>
    value === null ? unknown : formatHistoricalBenefitMoney(value)
  const percent = (value: number | string | null) =>
    value === null ? unknown : `${number(value)} %`
  const currentComparison =
    !missingSnapshot &&
    history.comparisons.find(
      (entry) =>
        entry.to === period.month && entry.quality !== "not_comparable",
    )
  const consumption = [
    ["confirmed_meals", "benefit_usage.ui.indicators.confirmed_meals"],
    ["confirmed_orders", "benefit_usage.ui.indicators.confirmed_orders"],
    [
      "monthly_subsidized_meals",
      "benefit_usage.ui.indicators.monthly_subsidized_meals",
    ],
    [
      "confirmed_meals_without_monthly_subsidy",
      "benefit_usage.ui.without_subsidy",
    ],
    [
      "company_subsidy_amount",
      "benefit_usage.ui.indicators.company_subsidy_amount",
    ],
  ] as const
  const visibleConsumption = missingSnapshot
    ? consumption.filter(([key]) => metrics[key] !== null)
    : consumption
  const visibleTrends = missingSnapshot
    ? history.trends.filter((entry) => entry.metrics.confirmed_meals !== null)
    : history.trends
  const visibleReasons = missingSnapshot
    ? Object.entries(history.unavailable_reasons).filter(
        ([, reason]) =>
          reason !== "historical_snapshot_missing" &&
          reason !== "retained_records_current_roster",
      )
    : Object.entries(history.unavailable_reasons)
  const maxMeals = Math.max(
    1,
    ...visibleTrends.flatMap((entry) =>
      entry.metrics.confirmed_meals === null
        ? []
        : [entry.metrics.confirmed_meals],
    ),
  )

  return (
    <>
      <div className="text-muted-foreground flex flex-wrap items-center gap-2 text-sm">
        {period.state !== "incomplete" && period.state !== "closed" && (
          <>
            <Badge variant="secondary">{t(`${p}.state.${period.state}`)}</Badge>
            <span>{t(`${p}.source.${period.source}`)}</span>
          </>
        )}
        {!missingSnapshot && period.captured_at && (
          <time className="min-w-0 break-words" dateTime={period.captured_at}>
            {t(`${p}.captured_at`, { date: capturedAt(period.captured_at) })}
          </time>
        )}
        {period.fictional && (
          <Badge variant="outline">{t(`${p}.fictional`)}</Badge>
        )}
      </div>
      {missingSnapshot && (
        <Alert>
          <AlertTitle className="line-clamp-none min-w-0 break-words">
            {t(`${p}.missing_title`)}
          </AlertTitle>
          <AlertDescription>{t(`${p}.missing_description`)}</AlertDescription>
        </Alert>
      )}

      {visibleConsumption.length > 0 && (
        <BenefitUsageCollapsibleCard
          title={t(
            missingSnapshot
              ? `${p}.partial_consumption`
              : "benefit_usage.ui.consumption",
          )}
          defaultOpen
        >
          {missingSnapshot && (
            <p className="text-muted-foreground text-sm">
              {t(`${p}.reconstructed_origin`)}
            </p>
          )}
          <dl className="grid gap-4 sm:grid-cols-2">
            {visibleConsumption.map(([key, label]) => (
              <Metric
                key={key}
                label={t(label)}
                value={
                  key === "company_subsidy_amount"
                    ? money(metrics[key])
                    : number(metrics[key])
                }
              />
            ))}
          </dl>
        </BenefitUsageCollapsibleCard>
      )}

      {!missingSnapshot && (
        <div className="grid items-start gap-4 lg:grid-cols-2">
          <BenefitUsageCollapsibleCard
            title={t("benefit_usage.ui.participation")}
          >
            <dl className="grid gap-4 sm:grid-cols-2">
              <Metric
                label={t(`${p}.employees_of_period`)}
                value={number(metrics.employees)}
              />
              <Metric
                label={t(`${p}.eligible_employees`)}
                value={number(metrics.eligible_employees)}
              />
              <Metric
                label={t(`${p}.eligible_participants`)}
                value={number(metrics.eligible_with_confirmed_orders)}
              />
              <Metric
                label={t("benefit_usage.ui.participation_percent")}
                value={percent(metrics.participation_percent)}
              />
              <Metric
                label={t("benefit_usage.ui.employees_with_confirmed_orders")}
                value={number(metrics.employees_with_confirmed_orders)}
              />
              <Metric
                label={t("benefit_usage.ui.average_per_employee")}
                value={number(metrics.average_confirmed_meals_per_employee)}
              />
            </dl>
            <p className="text-muted-foreground text-sm">
              {t("benefit_usage.ui.participation_note")}
            </p>
          </BenefitUsageCollapsibleCard>
          <BenefitUsageCollapsibleCard title={t("benefit_usage.ui.capacity")}>
            <dl className="grid gap-4 sm:grid-cols-2">
              <Metric
                label={t("benefit_usage.ui.quota")}
                value={number(metrics.monthly_quota_meals)}
              />
              <Metric
                label={t(
                  `${p}.${period.state === "closed" ? "available_at_close" : "available_at_capture"}`,
                )}
                value={number(
                  period.state === "closed"
                    ? metrics.monthly_unused_closed_meals
                    : metrics.monthly_available_meals,
                )}
              />
              <Metric
                label={t("benefit_usage.ui.reserved")}
                value={number(metrics.monthly_pending_reserved_meals)}
              />
            </dl>
            {period.state !== "closed" && (
              <p className="text-muted-foreground text-sm">
                {t(`${p}.available_note`)}
              </p>
            )}
          </BenefitUsageCollapsibleCard>
        </div>
      )}

      {visibleTrends.length > 0 && (
        <BenefitUsageCollapsibleCard title={t("benefit_usage.ui.trends")}>
          <p className="text-muted-foreground text-sm">
            {t(`${p}.trends_note`)}
          </p>
          <ul
            className="space-y-4"
            aria-label={t("benefit_usage.ui.indicators.confirmed_meals")}
          >
            {visibleTrends.map((entry) => (
              <li
                key={entry.month}
                className="bg-background space-y-3 rounded-lg border p-4"
              >
                <div className="flex flex-wrap items-center justify-between gap-2 text-sm">
                  <span>
                    {formatBenefitMonth(entry.month)}{" "}
                    <Badge variant="outline">
                      {t(`${p}.state.${entry.state}`)}
                    </Badge>
                  </span>
                  <span className="font-semibold">
                    {number(entry.metrics.confirmed_meals)}{" "}
                    {entry.metrics.confirmed_meals === null
                      ? ""
                      : t(`${p}.meals_unit`)}
                  </span>
                </div>
                <p className="text-muted-foreground text-xs">
                  {t(`${p}.source.${entry.source}`)}
                </p>
                {entry.metrics.confirmed_meals !== null && (
                  <div
                    aria-hidden="true"
                    className="bg-muted h-2 overflow-hidden rounded-full"
                  >
                    <div
                      className="bg-foreground h-full rounded-full"
                      style={{
                        width: `${(entry.metrics.confirmed_meals / maxMeals) * 100}%`,
                      }}
                    />
                  </div>
                )}
              </li>
            ))}
          </ul>
        </BenefitUsageCollapsibleCard>
      )}

      {!missingSnapshot && (
        <BenefitUsageCollapsibleCard title={t(`${p}.comparison_title`)}>
          {currentComparison ? (
            <>
              <p className="text-muted-foreground text-sm">
                {t(`${p}.comparison_period`, {
                  from: formatBenefitMonth(currentComparison.from),
                  to: formatBenefitMonth(currentComparison.to),
                })}{" "}
                <Badge variant="outline">
                  {t(`${p}.quality.${currentComparison.quality}`)}
                </Badge>
              </p>
              <dl className="grid gap-4 sm:grid-cols-2">
                {(
                  [
                    [
                      "confirmed_meals",
                      "benefit_usage.ui.indicators.confirmed_meals",
                    ],
                    [
                      "monthly_subsidized_meals",
                      "benefit_usage.ui.indicators.monthly_subsidized_meals",
                    ],
                    ["monthly_quota_meals", "benefit_usage.ui.quota"],
                    [
                      "eligible_with_confirmed_orders",
                      `${p}.eligible_participants`,
                    ],
                    [
                      "participation_percent",
                      "benefit_usage.ui.participation_percent",
                    ],
                    [
                      "company_subsidy_amount",
                      "benefit_usage.ui.indicators.company_subsidy_amount",
                    ],
                  ] as const
                ).map(([key, label]) => {
                  const change = currentComparison.changes[key]
                  const difference =
                    key === "participation_percent"
                      ? change?.difference_points
                      : change?.difference
                  const display =
                    difference === null || difference === undefined
                      ? unknown
                      : `${Number(difference) > 0 ? "+" : ""}${key === "company_subsidy_amount" ? money(String(difference)) : number(difference)}${key === "participation_percent" ? ` ${t(`${p}.points_unit`)}` : ""}`
                  return (
                    <Metric
                      key={key}
                      label={t(label)}
                      value={
                        <>
                          {display}
                          {difference !== null &&
                            difference !== undefined &&
                            change?.percent !== null &&
                            change?.percent !== undefined && (
                              <small className="text-muted-foreground block text-xs font-normal">
                                {t(`${p}.relative_change`, {
                                  percent: `${Number(change.percent) > 0 ? "+" : ""}${percent(change.percent)}`,
                                })}
                              </small>
                            )}
                        </>
                      }
                    />
                  )
                })}
              </dl>
            </>
          ) : (
            <p className="text-muted-foreground text-sm">
              {t(`${p}.not_comparable`)}
            </p>
          )}
        </BenefitUsageCollapsibleCard>
      )}
      {visibleReasons.length > 0 && (
        <BenefitUsageCollapsibleCard
          title={t("benefit_usage.ui.warnings_title")}
        >
          <p className="text-muted-foreground text-sm">
            {t(`${p}.limitations_note`)}
          </p>
          <ul className="text-muted-foreground list-disc space-y-2 pl-4 text-sm">
            {visibleReasons.map(([indicator, reason]) => (
              <li key={indicator}>
                {t(`${p}.indicator.${indicator}`, {
                  defaultValue: t(`${p}.indicator.other`),
                })}
                {": "}
                {t(`${p}.reason.${reason}`, {
                  defaultValue: t(`${p}.reason.source_unavailable`),
                })}
              </li>
            ))}
          </ul>
        </BenefitUsageCollapsibleCard>
      )}
    </>
  )
}

function Metric({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div className="min-w-0">
      <dt className="text-muted-foreground text-sm">{label}</dt>
      <dd className="mt-1 text-lg font-semibold break-words tabular-nums">
        {value}
      </dd>
    </div>
  )
}
