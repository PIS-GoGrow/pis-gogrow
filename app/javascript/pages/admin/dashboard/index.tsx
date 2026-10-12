import { Head, Link, router, usePage } from "@inertiajs/react"
import { ChevronRight } from "lucide-react"
import type { ReactNode } from "react"
import { useTranslation } from "react-i18next"

import ConsumptionStatusBadge from "@/components/admin/consumption-status-badge"
import HeadingSmall from "@/components/heading-small"
import NotificationBanners from "@/components/notification-banners"
import PageContainer from "@/components/page-container"
import StatusBadge from "@/components/status-badge"
import { Avatar, AvatarFallback } from "@/components/ui/avatar"
import { Button } from "@/components/ui/button"
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
} from "@/components/ui/card"
import { Progress } from "@/components/ui/progress"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { useFormatters } from "@/hooks/use-formatters"
import { useInitials } from "@/hooks/use-initials"
import AppLayout from "@/layouts/app-layout"
import { cn } from "@/lib/utils"
import { adminConsumers, adminDashboard, adminPayments } from "@/routes"
import type { AdminDashboardIndex } from "@/types/serializers"

const page = "pages.admin.dashboard"

export default function AdminDashboard({
  today,
  month,
  current_month,
  months,
  summary,
  payment_month,
  payments,
  debtors,
}: AdminDashboardIndex) {
  const { t } = useTranslation()
  const { formatMoneyShort } = useFormatters()
  const getInitials = useInitials()
  const { auth } = usePage().props
  const firstName = auth.user.name.split(" ")[0]

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
              <Select value={month} onValueChange={selectMonth}>
                <SelectTrigger
                  size="sm"
                  aria-label={t(`${page}.month_label`)}
                  className="bg-background dark:bg-background text-muted-foreground rounded-full border-none shadow-none"
                >
                  <SelectValue />
                </SelectTrigger>
                <SelectContent align="end">
                  {months.map((option) => (
                    <SelectItem key={option.key} value={option.key}>
                      {option.key === current_month
                        ? t(`${page}.this_month`)
                        : option.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
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
                  value={formatMoneyShort(summary.spending)}
                />
              </div>

              <p className="text-muted-foreground flex flex-wrap gap-x-3 gap-y-1 text-sm">
                <span>
                  {t(`${page}.benefit.paid`, {
                    amount: formatMoneyShort(summary.paid),
                  })}
                </span>
                <span>
                  {t(`${page}.benefit.pending`, {
                    amount: formatMoneyShort(summary.pending),
                  })}
                </span>
                {summary.projected > 0 && (
                  <span>
                    {t(`${page}.benefit.projected`, {
                      amount: formatMoneyShort(summary.projected),
                    })}
                  </span>
                )}
              </p>

              <Button
                asChild
                className="w-full bg-neutral-900 text-white hover:bg-neutral-700 dark:bg-neutral-100 dark:text-neutral-900 dark:hover:bg-neutral-300"
              >
                <Link href={adminPayments.index({ query: { month } }).url}>
                  {t(`${page}.benefit.view_detail`)}
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
                      {formatMoneyShort(payment.amount)}
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
              href={adminConsumers.index({ query: { filter: "pending" } }).url}
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
                      {formatMoneyShort(debtor.amount)}
                    </span>
                    <ConsumptionStatusBadge status={debtor.status} />
                  </Row>
                ))
              )}
            </Section>
          </div>
        </div>
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
