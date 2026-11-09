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
            <CardContent className="grid grid-cols-2 gap-2 px-4">
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
                className="col-span-2"
                label={t(`${page}.spending`)}
                value={formatMoney(summary.company_amount)}
                detail={t(`${page}.employee_amount`, {
                  amount: formatMoney(summary.employee_amount),
                })}
              />
            </CardContent>
          </Card>

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
                {providers.map((provider) => (
                  <SummaryRow key={provider.id ?? "none"}>
                    <span className="min-w-0 flex-1 truncate">
                      {provider.name ?? t(`${page}.no_provider`)}
                    </span>
                    <span className="text-muted-foreground shrink-0 text-sm">
                      {t(`${page}.meals`, { count: provider.meals })}
                    </span>
                    <span className="shrink-0 font-semibold">
                      {formatMoney(provider.company_amount)}
                    </span>
                  </SummaryRow>
                ))}
              </SummaryList>
            )}
          </SummarySection>
        </div>
      </PageContainer>
    </AppLayout>
  )
}
