import { Head, Link, router, usePage } from "@inertiajs/react"
import { ChevronRight } from "lucide-react"
import { type ReactNode, useState } from "react"
import { useTranslation } from "react-i18next"

import ConsumptionStatusBadge from "@/components/admin/consumption-status-badge"
import MonthSelect from "@/components/admin/month-select"
import ConsumptionDetailDialog from "@/components/admin/payments/consumption-detail-dialog"
import HeadingSmall from "@/components/heading-small"
import NotificationBanners from "@/components/notification-banners"
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
import { cn } from "@/lib/utils"
import {
  adminBenefitUsage,
  adminConsumers,
  adminDashboard,
  adminPayments,
} from "@/routes"
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
    <AppLayout>
      <Head title={t(`${page}.title`)} />

      <PageContainer
        title={t(`${page}.greeting`, { name: firstName })}
        description={today}
        titleVariant="prominent"
        compactHeading
      >
        <NotificationBanners />

        <div className="grid gap-4 lg:grid-cols-2 lg:gap-8">
          <Card className="bg-muted/60 h-fit gap-4 rounded-lg py-4 shadow-none">
            <CardHeader className="grid-cols-[1fr_auto] grid-rows-1 items-center px-4">
              <CardDescription>{t(`${page}.benefit.title`)}</CardDescription>
              <MonthSelect
                value={month}
                currentMonth={current_month}
                months={months}
                onValueChange={selectMonth}
                label={t(`${page}.month_label`)}
              />
            </CardHeader>

            <CardContent className="space-y-4 px-4">
              <p className="flex flex-wrap items-baseline gap-x-2">
                <strong className="text-3xl font-semibold tracking-tight">
                  {summary.meals_limit === null
                    ? summary.meals
                    : t(`${page}.benefit.meals_of_limit`, {
                        meals: summary.meals,
                        limit: summary.meals_limit,
                      })}
                </strong>
                <span className="text-lg font-medium">
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
                <Metric
                  label={t(`${page}.benefit.participation`)}
                  value={`${summary.participation}%`}
                />
                <Metric
                  label={t(`${page}.benefit.spending`)}
                  value={formatMoney(summary.spending)}
                />
              </div>

              <p className="text-muted-foreground flex flex-wrap gap-x-3 gap-y-1 text-sm">
                <span>
                  {t(`${page}.benefit.paid`, {
                    amount: formatMoney(summary.paid),
                  })}
                </span>
                <span>
                  {t(`${page}.benefit.pending`, {
                    amount: formatMoney(summary.pending),
                  })}
                </span>
                {summary.projected > 0 && (
                  <span>
                    {t(`${page}.benefit.projected`, {
                      amount: formatMoney(summary.projected),
                    })}
                  </span>
                )}
              </p>

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
              <Button asChild variant="link" className="w-full">
                <Link
                  href={adminBenefitUsage.analysis({ query: { month } }).url}
                >
                  {t("benefit_usage.ui.analysis_link")}
                </Link>
              </Button>
            </CardContent>
          </Card>

          <div className="grid content-start gap-8">
            <Section
              id="admin-payments-title"
              title={t(`${page}.payments.title`, { month: payment_month })}
              actionLabel={t(`${page}.payments.view`)}
              href={adminPayments.index().url}
            >
              {payments.length === 0 ? (
                <EmptyRow>
                  {t(`${page}.payments.empty`, { month: payment_month })}
                </EmptyRow>
              ) : (
                payments.map((payment) => (
                  <Row key={payment.name}>
                    <span className="min-w-0 flex-1 truncate">
                      {payment.name}
                    </span>
                    <span className="font-semibold">
                      {formatMoney(payment.amount)}
                    </span>
                    <StatusBadge status={payment.status} kind="payment" />
                  </Row>
                ))
              )}
            </Section>

            <Section
              id="admin-debts-title"
              title={t(`${page}.debts.title`)}
              actionLabel={t(`${page}.debts.view`)}
              href={
                adminConsumers.index({
                  query:
                    month === current_month
                      ? { filter: "pending" }
                      : { filter: "pending", month },
                }).url
              }
            >
              {debtors.length === 0 ? (
                <EmptyRow>{t(`${page}.debts.empty`)}</EmptyRow>
              ) : (
                debtors.map((debtor) => (
                  <Row
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
                      className="min-w-0 flex-1 truncate font-medium after:absolute after:inset-0 hover:underline"
                    >
                      {debtor.name}
                    </Link>
                    <span className="font-semibold">
                      {formatMoney(debtor.amount)}
                    </span>
                    <ConsumptionStatusBadge status={debtor.status} />
                  </Row>
                ))
              )}
            </Section>
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

function Metric({ label, value }: { label: string; value: string }) {
  return (
    <div className="bg-background rounded-xl border px-3 py-2.5">
      <p className="text-muted-foreground text-sm">{label}</p>
      <p className="mt-1 text-xl font-semibold">{value}</p>
    </div>
  )
}

function Section({
  id,
  title,
  actionLabel,
  href,
  children,
}: {
  id: string
  title: string
  actionLabel: string
  href: string
  children: ReactNode
}) {
  return (
    <section aria-labelledby={id} className="space-y-3">
      <div className="flex items-center justify-between">
        <div id={id}>
          <HeadingSmall title={title} />
        </div>
        <Button asChild variant="ghost" size="icon-sm" className="group">
          <Link href={href} aria-label={actionLabel}>
            <ChevronRight
              className="size-4 transition-transform group-hover:translate-x-0.5"
              aria-hidden="true"
            />
          </Link>
        </Button>
      </div>
      <Card className="gap-0 divide-y rounded-lg py-0 shadow-none">
        {children}
      </Card>
    </section>
  )
}

function Row({
  className,
  children,
}: {
  className?: string
  children: ReactNode
}) {
  return (
    <div className={cn("flex items-center gap-3 px-4 py-3", className)}>
      {children}
    </div>
  )
}

function EmptyRow({ children }: { children: ReactNode }) {
  return <p className="text-muted-foreground px-4 py-6 text-sm">{children}</p>
}
