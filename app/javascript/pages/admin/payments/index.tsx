import { Head } from "@inertiajs/react"
import { CircleCheck, Wallet } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import PeriodCard from "@/components/admin/payments/period-card"
// El detalle de un período es la misma tabla que ve el empleado en sus pagos.
import OrdersTable from "@/components/consumer/accounts/orders-table"
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
import {
  Sheet,
  SheetClose,
  SheetContent,
  SheetFooter,
  SheetTitle,
} from "@/components/ui/sheet"
import { Spinner } from "@/components/ui/spinner"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { useFormatters } from "@/hooks/use-formatters"
import { useIsMobile } from "@/hooks/use-mobile"
import AppLayout from "@/layouts/app-layout"
import { adminPayments } from "@/routes"
import type {
  Account,
  AdminPaymentsIndex,
  BreadcrumbItem,
  SimplifiedOrder,
} from "@/types"

interface PeriodDetail {
  orders: SimplifiedOrder[]
  month: string
  amount: number
}

export default function Index({
  accounts,
  history,
  providers,
  total_debt,
  current_month,
}: AdminPaymentsIndex) {
  const { t } = useTranslation()
  const { formatMoney } = useFormatters()
  const isMobile = useIsMobile()

  const [detail, setDetail] = useState<PeriodDetail | null>(null)
  const [loading, setLoading] = useState(false)

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.admin.payments.index.title"),
      href: adminPayments.index().url,
    },
  ]

  async function openDetail(account: Account) {
    setLoading(true)

    try {
      const response = await fetch(adminPayments.show(account.id).url, {
        headers: { Accept: "application/json" },
      })

      if (!response.ok) throw new Error(`Error ${response.status}`)

      setDetail((await response.json()) as PeriodDetail)
    } catch (error) {
      console.error(error)
    } finally {
      setLoading(false)
    }
  }

  const providerName = (id: number) =>
    providers.find((provider) => provider.id === id)?.name

  const meals =
    current_month.limit === null
      ? t("pages.admin.payments.index.meals_used", {
          count: current_month.meals,
        })
      : t("pages.admin.payments.index.meals_used_with_limit", {
          meals: current_month.meals,
          limit: current_month.limit,
        })

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t("pages.admin.payments.index.title")} />

      <PageContainer title={t("pages.admin.payments.index.title")}>
        <Stat
          label={t("pages.admin.payments.index.spending")}
          badge={
            <Badge variant="secondary">
              {t("pages.admin.payments.index.this_month")}
            </Badge>
          }
          value={formatMoney(current_month.amount)}
          detail={`| ${meals}`}
        />

        <HeadingSmall title={t("pages.admin.payments.index.section")} />

        <Sheet>
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
                value={formatMoney(total_debt)}
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
                      {t(
                        "pages.admin.payments.index.empty_history_description",
                      )}
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

          <SheetContent side={isMobile ? "bottom" : "right"} className="pt-8">
            <SheetTitle className="sr-only">
              {t("pages.admin.payments.index.detail_title")}
            </SheetTitle>

            {loading ? (
              <Spinner className="mx-auto size-8" />
            ) : (
              <OrdersTable
                orders={detail?.orders ?? []}
                month={detail?.month ?? ""}
                amount={detail?.amount ?? 0}
              />
            )}

            <SheetFooter>
              <SheetClose asChild>
                <Button>{t("common.close")}</Button>
              </SheetClose>
            </SheetFooter>
          </SheetContent>
        </Sheet>
      </PageContainer>
    </AppLayout>
  )
}
