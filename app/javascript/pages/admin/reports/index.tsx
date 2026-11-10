import { Head, Link, router } from "@inertiajs/react"
import { ArrowLeft, Users } from "lucide-react"
import { useTranslation } from "react-i18next"

import BenefitMetric from "@/components/admin/benefit-metric"
import {
  SummaryList,
  SummaryRow,
  SummarySection,
} from "@/components/admin/summary-section"
import { DateRangePicker } from "@/components/date-picker"
import PageContainer from "@/components/page-container"
import { Button } from "@/components/ui/button"
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
} from "@/components/ui/card"
import {
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyMedia,
  EmptyTitle,
} from "@/components/ui/empty"
import { Label } from "@/components/ui/label"
import { Progress } from "@/components/ui/progress"
import { useFormatters } from "@/hooks/use-formatters"
import AppLayout from "@/layouts/app-layout"
import { adminDashboard, adminReports } from "@/routes"
import type { BreadcrumbItem } from "@/types"
import type { AdminReportsIndex } from "@/types/serializers"

const page = "pages.admin.reports.index"

export default function AdminReports({
  from,
  to,
  default_from,
  default_to,
  min,
  max,
  month_label,
  presets,
  summary,
  providers,
  daily_consumption = [],
  delivery_methods = {
    office: { orders: 0, meals: 0 },
    home: { orders: 0, meals: 0 },
  },
}: AdminReportsIndex) {
  const { t } = useTranslation()
  const { formatMoney } = useFormatters()

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.admin.dashboard.title"),
      href: adminDashboard.index().url,
    },
    { title: t(`${page}.title`), href: adminReports.index().url },
  ]

  function selectRange(desde: string, hasta: string) {
    const isDefault = desde === default_from && hasta === default_to

    router.get(
      adminReports.index({ query: isDefault ? {} : { desde, hasta } }).url,
      {},
      { preserveScroll: true },
    )
  }

  const totalAmount = summary.company_amount + summary.employee_amount
  const companyPercent =
    totalAmount > 0
      ? Math.round((summary.company_amount / totalAmount) * 100)
      : null
  const employeePercent = companyPercent !== null ? 100 - companyPercent : null

  const avgMealsPerParticipant =
    summary.participants > 0
      ? (summary.meals / summary.participants).toFixed(1)
      : null

  const avgSubsidy =
    summary.meals > 0 ? summary.company_amount / summary.meals : null

  const officeDelivery = delivery_methods?.office ?? { orders: 0, meals: 0 }
  const homeDelivery = delivery_methods?.home ?? { orders: 0, meals: 0 }
  const totalDeliveryMeals = officeDelivery.meals + homeDelivery.meals
  const officePercent =
    totalDeliveryMeals > 0
      ? Math.round((officeDelivery.meals / totalDeliveryMeals) * 100)
      : null
  const homePercent = officePercent !== null ? 100 - officePercent : null

  const maxDailyMeals = Math.max(
    1,
    ...daily_consumption.map((day) => day.meals),
  )

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t(`${page}.title`)} />

      <PageContainer
        title={t(`${page}.title`)}
        back={
          <Button variant="ghost" size="icon" asChild>
            <Link href={adminDashboard.index()} aria-label={t(`${page}.back`)}>
              <ArrowLeft aria-hidden="true" />
            </Link>
          </Button>
        }
      >
        <div className="flex items-center justify-between gap-4">
          <Label
            htmlFor="reports-period"
            className="text-muted-foreground font-normal"
          >
            {t(`${page}.period`)}
          </Label>
          <DateRangePicker
            id="reports-period"
            from={from}
            to={to}
            min={min}
            max={max}
            label={month_label}
            commitOnComplete
            presets={presets.map((preset) => ({
              ...preset,
              label: t(`${page}.presets.${preset.key}`),
            }))}
            className="bg-card dark:bg-card text-muted-foreground dark:border-border hover:text-muted-foreground h-9 min-w-0 gap-1.5 rounded-lg border-[#E8E8E8] px-3 shadow-none"
            onChange={selectRange}
          />
        </div>

        <div className="grid gap-4 lg:grid-cols-2 lg:gap-8">
          <Card className="bg-muted/60 h-fit gap-4 rounded-lg py-4 shadow-none">
            <CardHeader className="grid-rows-1 items-center px-4">
              <CardDescription>{t(`${page}.summary`)}</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4 px-4">
              <div className="grid grid-cols-2 gap-2">
                <BenefitMetric
                  label={t(`${page}.adhesion`)}
                  value={`${summary.adhesion}%`}
                  detail={t(`${page}.adhesion_detail`, {
                    participants: summary.participants,
                    count: summary.employees,
                  })}
                />
                <BenefitMetric
                  label={t(`${page}.orders`)}
                  value={String(summary.orders)}
                  detail={t(`${page}.meals`, { count: summary.meals })}
                />
                <BenefitMetric
                  label={t(`${page}.avg_per_participant`)}
                  value={
                    avgMealsPerParticipant !== null
                      ? `${avgMealsPerParticipant}`
                      : "—"
                  }
                  detail={t(`${page}.avg_per_participant_detail`)}
                />
                <BenefitMetric
                  label={t(`${page}.avg_subsidy`)}
                  value={avgSubsidy !== null ? formatMoney(avgSubsidy) : "—"}
                  detail={t(`${page}.avg_subsidy_detail`)}
                />
                <BenefitMetric
                  className="col-span-2"
                  label={t(`${page}.spending`)}
                  value={formatMoney(summary.company_amount)}
                  detail={t(`${page}.employee_amount`, {
                    amount: formatMoney(summary.employee_amount),
                  })}
                />
              </div>

              <div className="pt-1">
                <Progress
                  value={summary.adhesion}
                  aria-label={t(`${page}.adhesion`)}
                  className="h-2"
                />
              </div>
            </CardContent>
          </Card>

          <Card className="bg-muted/60 h-fit gap-4 rounded-lg py-4 shadow-none">
            <CardHeader className="grid-rows-1 items-center px-4">
              <CardDescription>
                {t(`${page}.spending_distribution`)}
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4 px-4">
              <div className="grid grid-cols-2 gap-2">
                <BenefitMetric
                  label={t(`${page}.company_subsidy`)}
                  value={companyPercent !== null ? `${companyPercent}%` : "—"}
                  detail={
                    companyPercent !== null
                      ? t(`${page}.provider_share`, { percent: companyPercent })
                      : undefined
                  }
                />
                <BenefitMetric
                  label={t(`${page}.employee_contribution`)}
                  value={employeePercent !== null ? `${employeePercent}%` : "—"}
                  detail={
                    employeePercent !== null
                      ? t(`${page}.provider_share`, {
                          percent: employeePercent,
                        })
                      : undefined
                  }
                />
                <BenefitMetric
                  className="col-span-2"
                  label={t(`${page}.total_spent`)}
                  value={formatMoney(totalAmount)}
                />
              </div>

              <div className="space-y-1.5 pt-1">
                <div
                  aria-hidden="true"
                  className="bg-muted flex h-3 w-full overflow-hidden rounded-full"
                >
                  {companyPercent !== null ? (
                    <>
                      <div
                        className="bg-foreground h-full transition-all"
                        style={{ width: `${companyPercent}%` }}
                      />
                      <div
                        className="bg-muted-foreground/40 h-full transition-all"
                        style={{ width: `${employeePercent}%` }}
                      />
                    </>
                  ) : (
                    <div className="bg-muted h-full w-full" />
                  )}
                </div>
                <div className="text-muted-foreground flex flex-wrap items-center justify-between gap-2 text-xs">
                  <span className="flex items-center gap-1.5">
                    <span className="bg-foreground inline-block size-2 rounded-full" />
                    {t(`${page}.company_subsidy`)}
                    {companyPercent !== null && `: ${companyPercent}%`}
                  </span>
                  <span className="flex items-center gap-1.5">
                    <span className="bg-muted-foreground/40 inline-block size-2 rounded-full" />
                    {t(`${page}.employee_contribution`)}
                    {employeePercent !== null && `: ${employeePercent}%`}
                  </span>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        <div className="grid gap-4 lg:grid-cols-2 lg:gap-8">
          <Card className="bg-muted/60 h-fit gap-4 rounded-lg py-4 shadow-none">
            <CardHeader className="grid-rows-1 items-center px-4">
              <CardDescription>{t(`${page}.daily_activity`)}</CardDescription>
            </CardHeader>
            <CardContent className="space-y-3 px-4">
              {daily_consumption.length === 0 ? (
                <p className="text-muted-foreground py-6 text-center text-sm">
                  {t(`${page}.daily_activity_empty`)}
                </p>
              ) : (
                <div className="space-y-2">
                  <div
                    tabIndex={0}
                    aria-label={t(`${page}.daily_activity`)}
                    className="flex h-36 items-end justify-between gap-1 overflow-x-auto px-1 pt-8 pb-1"
                  >
                    {daily_consumption.map((day) => {
                      const heightPercent = Math.max(
                        8,
                        Math.round((day.meals / maxDailyMeals) * 100),
                      )
                      const dateParts = day.date.split("-")
                      const formattedDate = `${dateParts[2]}/${dateParts[1]}`

                      return (
                        <div
                          key={day.date}
                          className="group relative flex h-full min-w-[22px] flex-1 flex-col items-center justify-end"
                        >
                          <div className="bg-foreground text-background pointer-events-none absolute top-0 z-10 hidden rounded px-1.5 py-0.5 text-[10px] font-medium whitespace-nowrap shadow-sm group-focus-within:block group-hover:block">
                            {t(`${page}.meals`, { count: day.meals })}
                          </div>
                          <div className="flex h-20 w-full items-end justify-center">
                            <div
                              className="bg-foreground/85 hover:bg-foreground w-full max-w-[24px] rounded-t-sm transition-all"
                              style={{ height: `${heightPercent}%` }}
                              aria-label={`${formattedDate}: ${t(`${page}.meals`, { count: day.meals })}`}
                            />
                          </div>
                          <span className="text-muted-foreground mt-1 text-[10px] tabular-nums">
                            {formattedDate}
                          </span>
                        </div>
                      )
                    })}
                  </div>
                </div>
              )}
            </CardContent>
          </Card>

          <Card className="bg-muted/60 h-fit gap-4 rounded-lg py-4 shadow-none">
            <CardHeader className="grid-rows-1 items-center px-4">
              <CardDescription>{t(`${page}.delivery_methods`)}</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4 px-4">
              <div className="grid grid-cols-2 gap-2">
                <BenefitMetric
                  label={t(`${page}.delivery_office`)}
                  value={
                    officePercent !== null ? `${officeDelivery.meals}` : "—"
                  }
                  detail={
                    officePercent !== null
                      ? t(`${page}.provider_share`, { percent: officePercent })
                      : undefined
                  }
                />
                <BenefitMetric
                  label={t(`${page}.delivery_home`)}
                  value={homePercent !== null ? `${homeDelivery.meals}` : "—"}
                  detail={
                    homePercent !== null
                      ? t(`${page}.provider_share`, { percent: homePercent })
                      : undefined
                  }
                />
              </div>

              <div className="space-y-1.5 pt-1">
                <div
                  aria-hidden="true"
                  className="bg-muted flex h-3 w-full overflow-hidden rounded-full"
                >
                  {officePercent !== null ? (
                    <>
                      <div
                        className="bg-foreground h-full transition-all"
                        style={{ width: `${officePercent}%` }}
                      />
                      <div
                        className="bg-muted-foreground/40 h-full transition-all"
                        style={{ width: `${homePercent}%` }}
                      />
                    </>
                  ) : (
                    <div className="bg-muted h-full w-full" />
                  )}
                </div>
                <div className="text-muted-foreground flex flex-wrap items-center justify-between gap-2 text-xs">
                  <span className="flex items-center gap-1.5">
                    <span className="bg-foreground inline-block size-2 rounded-full" />
                    {t(`${page}.delivery_office`)}
                    {officePercent !== null && `: ${officePercent}%`}
                  </span>
                  <span className="flex items-center gap-1.5">
                    <span className="bg-muted-foreground/40 inline-block size-2 rounded-full" />
                    {t(`${page}.delivery_home`)}
                    {homePercent !== null && `: ${homePercent}%`}
                  </span>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        <SummarySection
          id="reports-providers-title"
          title={t(`${page}.providers`)}
        >
          {providers.length === 0 ? (
            <Empty className="min-h-[35svh] border-0 md:min-h-0 md:border">
              <EmptyHeader>
                <EmptyMedia variant="icon">
                  <Users aria-hidden="true" />
                </EmptyMedia>
                <EmptyTitle>{t(`${page}.empty_title`)}</EmptyTitle>
                <EmptyDescription>
                  {t(`${page}.empty_description`)}
                </EmptyDescription>
              </EmptyHeader>
            </Empty>
          ) : (
            <SummaryList>
              {providers.map((provider) => {
                const share =
                  summary.meals > 0
                    ? Math.round((provider.meals / summary.meals) * 100)
                    : 0

                return (
                  <SummaryRow key={provider.id ?? "none"}>
                    <div className="min-w-0 flex-1 space-y-1">
                      <div className="flex items-center justify-between gap-2">
                        <span className="truncate font-medium">
                          {provider.name ?? t(`${page}.no_provider`)}
                        </span>
                        <span className="text-muted-foreground shrink-0 text-xs">
                          {t(`${page}.provider_share`, { percent: share })}
                        </span>
                      </div>
                      <div
                        aria-hidden="true"
                        className="bg-muted h-1.5 w-full overflow-hidden rounded-full"
                      >
                        <div
                          className="bg-foreground h-full rounded-full transition-all"
                          style={{ width: `${share}%` }}
                        />
                      </div>
                    </div>
                    <span className="text-muted-foreground shrink-0 text-sm">
                      {t(`${page}.meals`, { count: provider.meals })}
                    </span>
                    <span className="shrink-0 font-semibold">
                      {formatMoney(provider.company_amount)}
                    </span>
                  </SummaryRow>
                )
              })}
            </SummaryList>
          )}
        </SummarySection>
      </PageContainer>
    </AppLayout>
  )
}
