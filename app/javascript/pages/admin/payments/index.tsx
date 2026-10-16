import { Head, router } from "@inertiajs/react"
import { CircleCheck, Wallet } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import MonthSelect from "@/components/admin/month-select"
import BankDetails from "@/components/admin/payments/bank-details"
import ConsumptionDetailDialog, {
  type ConsumptionDetail,
} from "@/components/admin/payments/consumption-detail-dialog"
import PeriodCard from "@/components/admin/payments/period-card"
import HeadingSmall from "@/components/heading-small"
import PageContainer from "@/components/page-container"
import Stat from "@/components/stat"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import {
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyMedia,
  EmptyTitle,
} from "@/components/ui/empty"
import { Progress } from "@/components/ui/progress"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { useFormatters } from "@/hooks/use-formatters"
import AppLayout from "@/layouts/app-layout"
import { adminPayments } from "@/routes"
import type { Account, AdminPaymentsIndex, BreadcrumbItem } from "@/types"

export default function Index({
  accounts,
  history,
  providers,
  total_debt,
  total_meals,
  month,
  current_month,
  months,
  summary,
  consumption,
}: AdminPaymentsIndex) {
  const { t } = useTranslation()
  const { formatMoneyShort } = useFormatters()

  const [open, setOpen] = useState(false)
  const [detail, setDetail] = useState<ConsumptionDetail | null>(null)
  const [providerId, setProviderId] = useState<number | null>(null)
  const [loading, setLoading] = useState(false)

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.admin.payments.index.title"),
      href: adminPayments.index().url,
    },
  ]

  // preserveState mantiene la pestaña de abajo al cambiar el mes de la tarjeta.
  function selectMonth(key: string) {
    router.get(
      adminPayments.index({
        query: key === current_month ? {} : { month: key },
      }).url,
      {},
      { preserveScroll: true, preserveState: true },
    )
  }

  // Sin proveedor elegido, el panel abre el primero del mes por nombre.
  function openMonthDetail() {
    setDetail(consumption)
    setProviderId(null)
    setOpen(true)
  }

  async function openDetail(account: Account) {
    setProviderId(account.provider_id)
    setOpen(true)
    setLoading(true)

    try {
      const response = await fetch(adminPayments.show(account.id).url, {
        headers: { Accept: "application/json" },
      })

      if (!response.ok) throw new Error(`Error ${response.status}`)

      setDetail((await response.json()) as ConsumptionDetail)
    } catch (error) {
      console.error(error)
    } finally {
      setLoading(false)
    }
  }

  const providerName = (id: number) =>
    providers.find((provider) => provider.id === id)?.name

  const meals =
    summary.limit === null
      ? t("pages.admin.payments.index.meals_used", {
          count: summary.meals,
        })
      : t("pages.admin.payments.index.meals_used_with_limit", {
          meals: summary.meals,
          limit: summary.limit,
        })

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t("pages.admin.payments.index.title")} />

      <PageContainer title={t("pages.admin.payments.index.title")}>
        <Stat
          label={t("pages.admin.payments.index.spending")}
          badge={
            <MonthSelect
              value={month}
              currentMonth={current_month}
              months={months}
              onValueChange={selectMonth}
              label={t("pages.admin.payments.index.month_label")}
            />
          }
          value={formatMoneyShort(summary.amount)}
          detail={`| ${meals}`}
          action={
            <div className="grid w-full gap-4">
              {summary.limit !== null && (
                <Progress
                  value={Math.min(100, (summary.meals / summary.limit) * 100)}
                  aria-label={t("pages.admin.payments.index.spending")}
                />
              )}
              <Button
                disabled={consumption === null}
                onClick={openMonthDetail}
                className="w-full bg-neutral-900 text-white hover:bg-neutral-700 dark:bg-neutral-100 dark:text-neutral-900 dark:hover:bg-neutral-300"
              >
                {t("pages.admin.payments.index.view_detail")}
              </Button>
            </div>
          }
        />

        <HeadingSmall title={t("pages.admin.payments.index.section")} />

        <Tabs defaultValue="pending" className="gap-4">
          <TabsList className="w-full">
            <TabsTrigger value="pending">
              {t("pages.admin.payments.index.pending_tab")}
            </TabsTrigger>
            <TabsTrigger value="history">
              {t("pages.admin.payments.index.history_tab")}
            </TabsTrigger>
          </TabsList>

          <TabsContent value="pending" className="grid gap-4">
            <Stat
              label={t("pages.admin.payments.index.pending_payments")}
              badge={
                <Badge variant="secondary">
                  {t("pages.admin.payments.index.total_debt")}
                </Badge>
              }
              value={
                <>
                  {formatMoneyShort(total_debt)}{" "}
                  <span className="text-lg">
                    {t("pages.admin.payments.index.pending_meals", {
                      count: total_meals,
                    })}
                  </span>
                </>
              }
            />

            {providers.map((provider) => {
              const periods = accounts.filter(
                (account) => account.provider_id === provider.id,
              )

              return (
                <Card key={provider.id}>
                  <CardHeader>
                    <CardTitle>{provider.name}</CardTitle>
                  </CardHeader>

                  <CardContent className="grid gap-4">
                    <BankDetails provider={provider} />

                    {periods.length === 0 ? (
                      <p className="flex items-center gap-2 text-sm text-emerald-600 dark:text-emerald-400">
                        <CircleCheck className="size-4" aria-hidden="true" />
                        {t("pages.admin.payments.index.no_debt")}
                      </p>
                    ) : (
                      periods.map((account) => (
                        <PeriodCard
                          key={account.id}
                          account={account}
                          onOpenDetail={() => void openDetail(account)}
                        />
                      ))
                    )}
                  </CardContent>
                </Card>
              )
            })}
          </TabsContent>

          <TabsContent value="history" className="grid gap-4">
            {history.length === 0 ? (
              <Empty className="border">
                <EmptyHeader>
                  <EmptyMedia variant="icon">
                    <Wallet aria-hidden="true" />
                  </EmptyMedia>
                  <EmptyTitle>
                    {t("pages.admin.payments.index.empty_history_title")}
                  </EmptyTitle>
                  <EmptyDescription>
                    {t("pages.admin.payments.index.empty_history_description")}
                  </EmptyDescription>
                </EmptyHeader>
              </Empty>
            ) : (
              history.map((account) => (
                <PeriodCard
                  key={account.id}
                  account={account}
                  providerName={providerName(account.provider_id)}
                  onOpenDetail={() => void openDetail(account)}
                />
              ))
            )}
          </TabsContent>
        </Tabs>

        <ConsumptionDetailDialog
          detail={detail}
          providerId={providerId}
          onProviderChange={setProviderId}
          loading={loading}
          open={open}
          onOpenChange={setOpen}
        />
      </PageContainer>
    </AppLayout>
  )
}
