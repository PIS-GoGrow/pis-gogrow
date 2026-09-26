import { Head, Link, usePage } from "@inertiajs/react"
import { ChevronRight, Clock3, Sparkles, Star } from "lucide-react"
import type { ReactNode } from "react"
import { useTranslation } from "react-i18next"

import PageContainer from "@/components/page-container"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader } from "@/components/ui/card"
import AppLayout from "@/layouts/app-layout"
import { cn } from "@/lib/utils"
import { providerDashboard, providerOrders } from "@/routes"
import type { BreadcrumbItem, ProviderDashboardIndex } from "@/types"

type Props = ProviderDashboardIndex

interface DashboardMetricProps {
  icon?: ReactNode
  label: string
  value: number | string
  variant?: "default" | "destructive"
  valueFirst?: boolean
  className?: string
}

export default function ProviderDashboard({
  today,
  today_orders_count,
  pending_orders_count,
  office_orders_count,
  home_orders_count,
  order_deadline,
  month_orders_count,
  month_dishes_count,
  average_rating,
}: Props) {
  const { t } = useTranslation()
  const { auth } = usePage().props

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.provider_dashboard.index.title"),
      href: providerDashboard.index().url,
    },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t("pages.provider_dashboard.index.title")} />

      <PageContainer
        description={today}
        titleVariant="prominent"
        title={t("pages.provider_dashboard.index.greeting", {
          name: auth.user.name,
        })}
      >
        <div className="grid gap-4 lg:grid-cols-2">
          <Card className="dark:border-border dark:bg-muted dark:hover:bg-accent gap-3 rounded-lg border-[#E8E8E8] bg-[#F5F5F5] py-4 shadow-none transition-colors hover:bg-[#EEEEEE] lg:col-span-2">
            <CardContent className="px-4">
              <Button
                type="button"
                variant="ghost"
                className="group h-auto w-full cursor-pointer justify-start gap-3 p-0 text-left whitespace-normal hover:bg-transparent"
              >
                <span className="grid size-12 shrink-0 place-items-center rounded-full bg-[conic-gradient(#16a34a_0deg_270deg,var(--color-muted)_270deg_360deg)] p-1">
                  <span className="bg-card grid size-full place-items-center rounded-full">
                    <span className="text-sm font-semibold">3/4</span>
                  </span>
                </span>
                <span className="min-w-0 flex-1">
                  <span className="block text-base font-semibold">
                    {t("pages.provider_dashboard.index.profile.title")}
                  </span>
                  <span className="text-muted-foreground block text-sm font-normal">
                    {t("pages.provider_dashboard.index.profile.description")}
                  </span>
                </span>
                <span className="bg-card grid size-9 shrink-0 place-items-center rounded-full">
                  <ChevronRight
                    className="size-4 transition-transform group-hover:translate-x-0.5"
                    aria-hidden="true"
                  />
                </span>
              </Button>
            </CardContent>
          </Card>

          <Card className="dark:border-border dark:bg-muted gap-4 rounded-lg border-[#E8E8E8] bg-[#F5F5F5] py-4 shadow-none">
            <CardHeader className="grid-cols-[1fr_auto] grid-rows-1 items-center px-4">
              <p className="text-muted-foreground">
                {t("pages.provider_dashboard.index.orders.title")}
              </p>
              <Badge
                variant="secondary"
                className="bg-card text-muted-foreground px-2.5 py-1 text-sm font-normal"
              >
                {t("pages.provider_dashboard.index.orders.today")}
              </Badge>
            </CardHeader>
            <CardContent className="grid grid-cols-2 gap-2 px-4">
              <DashboardMetric
                className="bg-card dark:border-border rounded-xl border border-[#E9E9E9] px-3 py-2.5"
                label={t("pages.provider_dashboard.index.orders.confirmed")}
                value={today_orders_count - pending_orders_count}
              />
              <DashboardMetric
                className="bg-card dark:border-border rounded-xl border border-[#E9E9E9] px-3 py-2.5"
                label={t("pages.provider_dashboard.index.orders.pending")}
                value={pending_orders_count}
                variant="destructive"
              />
              <DashboardMetric
                className="bg-card dark:border-border rounded-xl border border-[#E9E9E9] px-3 py-2.5"
                label={t("pages.provider_dashboard.index.orders.office")}
                value={office_orders_count}
              />
              <DashboardMetric
                className="bg-card dark:border-border rounded-xl border border-[#E9E9E9] px-3 py-2.5"
                label={t("pages.provider_dashboard.index.orders.home")}
                value={home_orders_count}
              />
            </CardContent>
            <CardContent className="space-y-3 px-4">
              <Button
                asChild
                className="h-12 w-full rounded-lg text-sm font-normal"
              >
                <Link href={providerOrders.index().url}>
                  {t("pages.provider_dashboard.index.orders.view")}
                </Link>
              </Button>
              <Button
                type="button"
                variant="ghost"
                className="group h-auto w-full cursor-pointer justify-start gap-2 px-0 py-1 text-left text-sm font-normal whitespace-normal text-amber-700 hover:bg-amber-500/10 hover:text-amber-700 has-[>svg]:px-0 dark:text-amber-300 dark:hover:text-amber-300"
              >
                <Clock3
                  className="size-4 shrink-0 text-amber-400"
                  aria-hidden="true"
                />
                <span className="flex-1">
                  {order_deadline
                    ? t("pages.provider_dashboard.index.orders.deadline", {
                        time: order_deadline,
                      })
                    : t("pages.provider_dashboard.index.coming_soon")}
                </span>
                <ChevronRight
                  className="text-foreground size-4 transition-transform group-hover:translate-x-0.5"
                  aria-hidden="true"
                />
              </Button>
            </CardContent>
          </Card>

          <div className="flex flex-col gap-4">
            <section className="space-y-3" aria-labelledby="insights-title">
              <DashboardSectionButton
                id="insights-title"
                title={t("pages.provider_dashboard.index.insights.title")}
              />
              <div className="grid grid-cols-3 gap-2">
                <DashboardMetric
                  className="dark:border-border dark:bg-muted rounded-xl border border-[#E8E8E8] bg-[#F5F5F5] px-2 py-4"
                  label={t("pages.provider_dashboard.index.insights.orders")}
                  value={month_orders_count}
                  valueFirst
                />
                <DashboardMetric
                  className="dark:border-border dark:bg-muted rounded-xl border border-[#E8E8E8] bg-[#F5F5F5] px-2 py-4"
                  label={t("pages.provider_dashboard.index.insights.dishes")}
                  value={month_dishes_count}
                  valueFirst
                />
                <DashboardMetric
                  className="dark:border-border dark:bg-muted rounded-xl border border-[#E8E8E8] bg-[#F5F5F5] px-2 py-4"
                  icon={
                    <Star className="size-5 fill-current" aria-hidden="true" />
                  }
                  label={t("pages.provider_dashboard.index.insights.rating")}
                  value={average_rating ?? "—"}
                  valueFirst
                />
              </div>
              <div className="space-y-3 rounded-xl border border-violet-300 bg-gradient-to-br from-[#FCFAFF] to-[#EEF6FF] p-4 text-sm dark:border-violet-900 dark:from-violet-950/30 dark:to-slate-900/30">
                <p>
                  {t("pages.provider_dashboard.index.insights.description")}
                </p>
                <p className="text-muted-foreground flex items-center gap-1.5 text-xs">
                  <Sparkles
                    className="size-4 shrink-0 text-violet-500"
                    aria-hidden="true"
                  />
                  {t("pages.provider_dashboard.index.insights.generated")}
                </p>
              </div>
            </section>

            <section className="space-y-3" aria-labelledby="payments-title">
              <DashboardSectionButton
                id="payments-title"
                title={t("pages.provider_dashboard.index.payments.title")}
              />
              <Card className="dark:border-border dark:bg-muted gap-3 rounded-lg border-[#E8E8E8] bg-[#F5F5F5] p-4 shadow-none">
                <CardContent className="flex items-center justify-between gap-2 px-0">
                  <p className="text-muted-foreground text-sm">
                    {t("pages.provider_dashboard.index.payments.pending")}
                  </p>
                  <Badge
                    variant="secondary"
                    className="bg-card text-muted-foreground"
                  >
                    {t("pages.provider_dashboard.index.payments.total")}
                  </Badge>
                </CardContent>
                <CardContent className="px-0">
                  <p className="text-sm font-semibold">
                    {t("pages.provider_dashboard.index.payments.description")}
                  </p>
                </CardContent>
              </Card>
            </section>
          </div>
        </div>
      </PageContainer>
    </AppLayout>
  )
}

function DashboardSectionButton({ id, title }: { id: string; title: string }) {
  return (
    <h3 id={id}>
      <Button
        type="button"
        variant="ghost"
        className="group hover:text-foreground h-auto w-full cursor-pointer justify-between p-0 text-base font-semibold hover:bg-transparent has-[>svg]:px-0"
      >
        <span className="group-hover:underline">{title}</span>
        <ChevronRight
          className="size-4 transition-transform group-hover:translate-x-0.5"
          aria-hidden="true"
        />
      </Button>
    </h3>
  )
}

function DashboardMetric({
  icon,
  label,
  value,
  variant = "default",
  valueFirst = false,
  className,
}: DashboardMetricProps) {
  const valueContent = (
    <p className="flex items-center justify-center gap-1 text-2xl font-semibold tracking-tight">
      {icon}
      {value}
    </p>
  )

  return (
    <div className={cn("min-w-0", valueFirst && "text-center", className)}>
      {valueFirst && valueContent}
      <p
        className={cn(
          valueFirst ? "text-sm" : "text-muted-foreground text-sm",
          variant === "destructive" && "text-destructive",
        )}
      >
        {label}
      </p>
      {!valueFirst && (
        <p className="mt-1 text-2xl font-semibold tracking-tight">{value}</p>
      )}
    </div>
  )
}
