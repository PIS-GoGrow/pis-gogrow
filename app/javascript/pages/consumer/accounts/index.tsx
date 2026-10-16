import { Head } from "@inertiajs/react"
import { CircleCheck } from "lucide-react"
import { useState } from "react"
import type { JSX } from "react"
import { useTranslation } from "react-i18next"

import {
  AdaptableDialog,
  AdaptableDialogContent,
  AdaptableDialogFooter,
} from "@/components/adaptable-dialog"
import AccountCard from "@/components/consumer/accounts/account-card"
import OrdersTable from "@/components/consumer/accounts/orders-table"
import PaymentHistoryCard from "@/components/consumer/accounts/payment-history-card"
import { ConsumerMobileNav } from "@/components/consumer/consumer-mobile-nav"
import { Button } from "@/components/ui/button"
import { Spinner } from "@/components/ui/spinner"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { useFormatters } from "@/hooks/use-formatters"
import AppLayout from "@/layouts/app-layout"
import { consumerAccounts } from "@/routes"
import type {
  Account,
  BreadcrumbItem,
  Provider,
  SimplifiedOrder,
} from "@/types"

interface AccountProps {
  accounts: Account[]
  history_accounts: Account[]
  providers: Provider[]
  history: boolean
  current_month_debt: number
  current_month_ordered: number
  total_debt: number
  benefit_available: number
}

interface AccountDetail {
  orders: SimplifiedOrder[]
  month: string
  amount: number
}

export default function Index({
  accounts,
  history_accounts,
  providers,
  history,
  current_month_debt,
  current_month_ordered,
  total_debt,
  benefit_available,
}: AccountProps) {
  const { t } = useTranslation()
  const { formatMoneyShort } = useFormatters()

  const [loading, setLoading] = useState(false)
  const [detail, setDetail] = useState<AccountDetail | null>(null)
  const [dialogOpen, setDialogOpen] = useState(false)

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.accounts.index.payments"),
      href: consumerAccounts.index().url,
    },
  ]

  const totalPendingViandas = accounts.reduce(
    (sum, a) => sum + (a.orders_amount_sum ?? 0),
    0,
  )

  async function handleSeeCurrentMonthDetail() {
    const currentAccount = accounts.find((a) => a.current) ?? accounts[0]
    if (!currentAccount) return

    setLoading(true)
    setDialogOpen(true)
    try {
      const response = await fetch(
        consumerAccounts.show(currentAccount.id).url,
        {
          headers: { Accept: "application/json" },
        },
      )
      if (!response.ok) throw new Error(`Error ${response.status}`)
      const data = (await response.json()) as AccountDetail
      setDetail(data)
    } catch (err) {
      console.error(err)
    } finally {
      setLoading(false)
    }
  }

  const accountsJSX: Record<string | number, JSX.Element[]> = {}

  accounts.forEach((account: Account) => {
    const providerId = account.provider_id

    if (!accountsJSX[providerId]) {
      accountsJSX[providerId] = []
    }

    accountsJSX[providerId].push(
      <AccountCard
        key={account.id}
        setDetail={setDetail}
        setLoading={setLoading}
        account={account}
        onOpenDetail={() => setDialogOpen(true)}
      />,
    )
  })

  const providersJSX = providers.map((p) => (
    <div key={p.id} className="border-border space-y-4 rounded-lg border p-4">
      <h3 className="text-foreground text-xl font-bold">{p.name}</h3>

      {accountsJSX[p.id] ? (
        <div className="grid gap-3">{accountsJSX[p.id]}</div>
      ) : (
        <div className="flex items-center text-sm font-medium text-emerald-600 dark:text-emerald-400">
          <CircleCheck className="mr-2 size-4" />
          {t("pages.accounts.index.no_debt")}
        </div>
      )}
    </div>
  ))

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t("pages.accounts.index.payments")} />

      <div className="mx-auto grid w-full max-w-128 gap-6 p-5 pb-24 md:pb-5">
        <h1 className="text-2xl font-bold">
          {t("pages.accounts.index.payments")}
        </h1>

        <div className="border-border bg-muted space-y-4 rounded-lg border p-4">
          <div className="flex items-center justify-between">
            <span className="text-muted-foreground text-base font-medium">
              {t("pages.accounts.index.spending")}
            </span>
            <span className="bg-background text-muted-foreground rounded-full px-3 py-1 text-sm font-medium shadow-none">
              {t("pages.accounts.index.this_month")}
            </span>
          </div>

          <div className="flex flex-wrap items-baseline gap-1.5">
            <span className="text-foreground text-2xl font-bold">
              {formatMoneyShort(current_month_debt)}
            </span>
            <span className="text-foreground text-sm font-semibold">
              | {current_month_ordered} de {benefit_available}{" "}
              {t("pages.accounts.index.viandas_consumed", "viandas consumidas")}
            </span>
          </div>

          <div className="bg-muted-foreground/20 h-2 w-full overflow-hidden rounded-full">
            <div
              className="h-full rounded-full bg-[#171717] transition-all dark:bg-zinc-100"
              style={{
                width: `${Math.min(
                  100,
                  benefit_available > 0
                    ? (current_month_ordered / benefit_available) * 100
                    : 0,
                )}%`,
              }}
            />
          </div>

          <Button
            type="button"
            className="h-10 w-full rounded-[10px] bg-[#171717] text-base font-medium text-[#fafafa] hover:bg-[#171717]/90 dark:bg-zinc-100 dark:text-zinc-900"
            onClick={() => {
              void handleSeeCurrentMonthDetail()
            }}
          >
            {t(
              "pages.accounts.index.see_consumption_detail",
              "Ver detalle del consumo",
            )}
          </Button>
        </div>

        <div>
          <h2 className="text-foreground mb-3 text-xl font-bold">
            {t("pages.accounts.index.payments")}
          </h2>

          <Tabs
            defaultValue={history ? "history" : "pending"}
            className="w-full"
          >
            <TabsList className="bg-muted w-full rounded-[10px] p-1">
              <TabsTrigger value="pending" className="rounded-lg">
                {t("pages.accounts.index.pending")}
              </TabsTrigger>
              <TabsTrigger value="history" className="rounded-lg">
                {t("pages.accounts.index.history")}
              </TabsTrigger>
            </TabsList>

            <TabsContent className="mt-4 grid w-full gap-4" value="pending">
              <div className="border-border bg-muted space-y-2 rounded-lg border p-4">
                <div className="flex items-center justify-between">
                  <span className="text-muted-foreground text-base font-medium">
                    {t("pages.accounts.index.pending_payments")}
                  </span>
                  <span className="bg-background text-muted-foreground rounded-full px-3 py-1 text-sm font-medium shadow-none">
                    {t("pages.accounts.index.total_debt")}
                  </span>
                </div>
                <div className="flex items-baseline gap-2">
                  <span className="text-foreground text-2xl font-bold">
                    {formatMoneyShort(total_debt)}
                  </span>
                  {totalPendingViandas > 0 && (
                    <span className="text-foreground text-lg font-semibold">
                      ({totalPendingViandas}{" "}
                      {totalPendingViandas === 1
                        ? t("pages.accounts.show.lunch")
                        : t("pages.accounts.show.lunches")}
                      )
                    </span>
                  )}
                </div>
              </div>

              {providersJSX}
            </TabsContent>

            <TabsContent className="mt-4 grid w-full gap-4" value="history">
              {history_accounts.length === 0 ? (
                <p className="text-muted-foreground text-sm">
                  {t("pages.accounts.index.history_empty")}
                </p>
              ) : (
                history_accounts.map((account) => (
                  <PaymentHistoryCard
                    key={account.id}
                    account={account}
                    setDetail={setDetail}
                    setLoading={setLoading}
                    onOpenDetail={() => setDialogOpen(true)}
                  />
                ))
              )}
            </TabsContent>
          </Tabs>
        </div>

        <AdaptableDialog
          open={dialogOpen}
          onOpenChange={setDialogOpen}
          desktopVariant="sheet"
        >
          <AdaptableDialogContent className="pt-5">
            {loading ? (
              <Spinner className="mx-auto size-8" />
            ) : (
              <OrdersTable
                orders={detail ? detail.orders : []}
                month={String(detail?.month)}
                amount={Number(detail?.amount)}
              />
            )}

            <AdaptableDialogFooter className="mt-4">
              <Button
                type="button"
                className="h-11 w-full rounded-[10px] text-base font-medium"
                onClick={() => setDialogOpen(false)}
              >
                {t("common.close")}
              </Button>
            </AdaptableDialogFooter>
          </AdaptableDialogContent>
        </AdaptableDialog>
      </div>

      <ConsumerMobileNav />
    </AppLayout>
  )
}
