import { Head, Link, router, usePage } from "@inertiajs/react"
import { type ReactNode, useState } from "react"
import { useTranslation } from "react-i18next"

import BenefitMetric from "@/components/admin/benefit-metric"
import ConsumptionStatusBadge from "@/components/admin/consumption-status-badge"
import MonthSelect from "@/components/admin/month-select"
import ConsumptionDetailDialog from "@/components/admin/payments/consumption-detail-dialog"
import {
  SummaryList,
  SummaryRow,
  SummarySection,
} from "@/components/admin/summary-section"
import NotificationBanners, {
  NotificationInbox,
} from "@/components/notification-banners"
import PageContainer from "@/components/page-container"
import StatusBadge from "@/components/status-badge"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Button } from "@/components/ui/button"
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
} from "@/components/ui/card"
import { Progress } from "@/components/ui/progress"
import { useFormatters } from "@/hooks/use-formatters"
import { useInitials } from "@/hooks/use-initials"
import AppLayout from "@/layouts/app-layout"
import {
  adminBenefitUsage,
  adminConsumers,
  adminDashboard,
  adminPayments,
  adminReports,
} from "@/routes"
import type { BreadcrumbItem } from "@/types"
import type { AdminDashboardIndex } from "@/types/serializers"

const page = "pages.admin.dashboard"

export default function AdminDashboard({
  today,
  month,
  current_month,
  months,
  summary,
  consumption,
  payment_month,
  payments,
  debtors,
}: AdminDashboardIndex) {
  const { t } = useTranslation()
  const { formatMoney } = useFormatters()
  const getInitials = useInitials()
  const { auth } = usePage().props
  const firstName = auth.user.name.split(" ")[0]
  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t(`${page}.title`),
      href: adminDashboard.index().url,
    },
  ]
  // El panel del consumo se abre sobre el Inicio, con el mes del selector.
  const [detailOpen, setDetailOpen] = useState(false)
  const [providerId, setProviderId] = useState<number | null>(null)

  const progress = summary.meals_limit
    ? Math.min(100, (summary.meals / summary.meals_limit) * 100)
    : 0

  function selectMonth(key: string) {
    router.get(
      adminDashboard.index({
        query: key === current_month ? {} : { month: key },
      }).url,
      {},
      { preserveScroll: true },
    )
  }

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t(`${page}.title`)} />

      <PageContainer
        title={t(`${page}.greeting`, { name: firstName })}
        description={today}
        titleVariant="prominent"
        compactHeading
        actions={<NotificationInbox />}
        actionsCentered
      >
        <NotificationBanners />

        <div className="grid gap-4 lg:grid-cols-2 lg:gap-8">
          <Card className="bg-muted/60 h-fit gap-4 rounded-lg py-4 shadow-none">
            <CardHeader className="grid-cols-[1fr_auto] grid-rows-1 items-center px-4">
              <CardDescription className="text-base font-medium">
                {t(`${page}.benefit.title`)}
              </CardDescription>
              <MonthSelect
                value={month}
                currentMonth={current_month}
                months={months}
                onValueChange={selectMonth}
                label={t(`${page}.month_label`)}
              />
            </CardHeader>

            <CardContent className="space-y-4 px-4">
              <p className="flex flex-wrap items-baseline gap-x-1.5">
                <strong className="text-2xl font-bold tracking-tight">
                  {summary.meals_limit === null
                    ? summary.meals
                    : t(`${page}.benefit.meals_of_limit`, {
                        meals: summary.meals,
                        limit: summary.meals_limit,
                      })}
                </strong>
                <span className="text-lg font-semibold">
                  {t(`${page}.benefit.meals_ordered`, {
                    count: summary.meals_limit ?? summary.meals,
                  })}
                </span>
              </p>
              {summary.meals_limit !== null && (
                <Progress
                  value={progress}
                  aria-label={t(`${page}.benefit.title`)}
                />
              )}

              <div className="grid grid-cols-2 gap-2">
                <BenefitMetric
                  label={t(`${page}.benefit.participation`)}
                  value={`${summary.participation}%`}
                />
                <BenefitMetric
                  label={t(`${page}.benefit.spending`)}
                  value={formatMoney(summary.spending)}
                />
              </div>

              <div className="grid gap-3">
                <Button
                  disabled={consumption === null}
                  onClick={() => {
                    setProviderId(null)
                    setDetailOpen(true)
                  }}
                  className="w-full bg-neutral-900 text-white hover:bg-neutral-700 dark:bg-neutral-100 dark:text-neutral-900 dark:hover:bg-neutral-300"
                >
                  {t(`${page}.benefit.view_detail`)}
                </Button>
                <Button
                  asChild
                  variant="outline"
                  className="w-full border-neutral-300 bg-white text-neutral-900 hover:bg-neutral-50 md:hidden dark:border-neutral-600 dark:bg-neutral-800 dark:text-neutral-50 dark:hover:bg-neutral-700"
                >
                  <Link
                    href={adminBenefitUsage.analysis({ query: { month } }).url}
                  >
                    {t("benefit_usage.ui.analysis_link")}
                  </Link>
                </Button>
                <Button
                  asChild
                  variant="outline"
                  className="w-full border-neutral-300 bg-white text-neutral-900 hover:bg-neutral-50 dark:border-neutral-600 dark:bg-neutral-800 dark:text-neutral-50 dark:hover:bg-neutral-700"
                >
                  <Link href={adminReports.index().url}>
                    {t(`${page}.benefit.reports_link`)}
                  </Link>
                </Button>
              </div>
            </CardContent>
          </Card>

          <div className="grid content-start gap-8">
            <SummarySection
              id="admin-payments-title"
              title={t(`${page}.payments.title`, { month: payment_month })}
              action={{
                label: t(`${page}.payments.view`),
                href: adminPayments.index().url,
              }}
            >
              <SummaryList>
                {payments.length === 0 ? (
                  <EmptyRow>
                    {t(`${page}.payments.empty`, { month: payment_month })}
                  </EmptyRow>
                ) : (
                  payments.map((payment) => (
                    <SummaryRow key={payment.name}>
                      <span className="min-w-0 flex-1 truncate">
                        {payment.name}
                      </span>
                      <span className="font-semibold">
                        {formatMoney(payment.amount)}
                      </span>
                      <StatusBadge status={payment.status} kind="payment" />
                    </SummaryRow>
                  ))
                )}
              </SummaryList>
            </SummarySection>

            <SummarySection
              id="admin-debts-title"
              title={t(`${page}.debts.title`)}
              action={{
                label: t(`${page}.debts.view`),
                href: adminConsumers.index({
                  query:
                    month === current_month
                      ? { filter: "pending" }
                      : { filter: "pending", month },
                }).url,
              }}
            >
              <SummaryList>
                {debtors.length === 0 ? (
                  <EmptyRow>{t(`${page}.debts.empty`)}</EmptyRow>
                ) : (
                  debtors.map((debtor) => (
                    <SummaryRow
                      key={debtor.id}
                      className="hover:bg-accent/40 relative transition-colors"
                    >
                      <Avatar size="lg">
                        {debtor.avatar_url && (
                          <AvatarImage src={debtor.avatar_url} alt="" />
                        )}
                        <AvatarFallback className="text-foreground text-xs font-semibold">
                          {getInitials(debtor.name)}
                        </AvatarFallback>
                      </Avatar>
                      <Link
                        href={adminConsumers.show(debtor.id).url}
                        className="min-w-0 flex-1 truncate font-semibold after:absolute after:inset-0 hover:underline"
                      >
                        {debtor.name}
                      </Link>
                      <span className="font-semibold">
                        {formatMoney(debtor.amount)}
                      </span>
                      <ConsumptionStatusBadge status={debtor.status} />
                    </SummaryRow>
                  ))
                )}
              </SummaryList>
            </SummarySection>
          </div>
        </div>

        <ConsumptionDetailDialog
          detail={consumption}
          providerId={providerId}
          onProviderChange={setProviderId}
          loading={false}
          open={detailOpen}
          onOpenChange={setDetailOpen}
        />
      </PageContainer>
    </AppLayout>
  )
}

function EmptyRow({ children }: { children: ReactNode }) {
  return <p className="text-muted-foreground px-4 py-6 text-sm">{children}</p>
}
