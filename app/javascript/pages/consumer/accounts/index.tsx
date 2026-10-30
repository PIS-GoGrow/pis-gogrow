import { Head } from "@inertiajs/react"
import { CircleCheck } from "lucide-react"
import { useState } from "react"
import type { JSX } from "react"
import { useTranslation } from "react-i18next"

import {
  AdaptableDialog,
  AdaptableDialogClose,
  AdaptableDialogContent,
  AdaptableDialogFooter,
  AdaptableDialogTrigger,
} from "@/components/adaptable-dialog"
import AccountCard from "@/components/consumer/accounts/account-card"
import OrdersTable from "@/components/consumer/accounts/orders-table"
import PaymentHistoryCard from "@/components/consumer/accounts/payment-history-card"
import { ConsumerMobileNav } from "@/components/consumer/consumer-mobile-nav"
import { ProviderFilterSheet } from "@/components/consumer/provider-filter-sheet"
import BankDetails from "@/components/payments/bank-details"
import Stat from "@/components/stat"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Progress } from "@/components/ui/progress"
import { Spinner } from "@/components/ui/spinner"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import AppLayout from "@/layouts/app-layout"
import { formatMoney } from "@/lib/money"
import { consumerAccounts } from "@/routes"
import type {
  Account,
  BreadcrumbItem,
  PaymentProvider,
  SimplifiedOrder,
} from "@/types"

interface AccountProps {
  accounts: Account[]
  history_accounts: Account[]
  providers: PaymentProvider[]
  history: boolean
  current_month_debt: number
  current_month_detail: AccountDetail
  total_debt: number
  total_meals: number
  benefit_used: number
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
  current_month_detail,
  total_debt,
  total_meals,
  benefit_used,
  benefit_available,
}: AccountProps) {
  const { t } = useTranslation()

  const [loading, setLoading] = useState(false)
  const [detail, setDetail] = useState<AccountDetail | null>(null)
  const [activeProviders, setActiveProviders] = useState<Set<number>>(new Set())

  const selectedProviderId = activeProviders.values().next().value
  const filteredHistory =
    selectedProviderId == null
      ? history_accounts
      : history_accounts.filter(
          (account) => account.provider_id === selectedProviderId,
        )
  const filterLabel =
    providers.find(({ id }) => id === selectedProviderId)?.name ??
    t("pages.accounts.index.all_providers")

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.accounts.index.payments"),
      href: consumerAccounts.index().url,
    },
  ]

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
      />,
    )
  })

  const providersJSX = providers.map((p) => (
    <Card key={p.id} className="w-full py-4 shadow-none">
      <CardHeader className="px-4">
        <CardTitle className="text-lg font-bold">{p.name}</CardTitle>
      </CardHeader>

      <CardContent className="grid gap-4 px-4">
        <BankDetails provider={p} />

        {accountsJSX[p.id] ? (
          accountsJSX[p.id]
        ) : (
          <div className="flex items-center text-emerald-600 dark:text-emerald-400">
            <CircleCheck className="mr-2" size={16} />
            {t("pages.accounts.index.no_debt")}
          </div>
        )}
      </CardContent>
    </Card>
  ))

  const mealsUsed =
    benefit_available > 0
      ? t("pages.accounts.index.meals_used_with_limit", {
          count: benefit_available,
          meals: benefit_used,
          limit: benefit_available,
        })
      : t("pages.accounts.index.meals_used", { count: benefit_used })

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t("pages.accounts.index.payments")} />

      <div className="mx-auto grid w-full max-w-128 gap-6 p-5 pb-24 md:pb-5">
        <AdaptableDialog desktopVariant="sheet">
          <h1 className="text-2xl font-bold">
            {" "}
            {t("pages.accounts.index.payments")}{" "}
          </h1>
          <Stat
            label={t("pages.accounts.index.spending")}
            badge={
              <Badge variant="secondary" className="bg-background">
                {t("pages.accounts.index.this_month")}
              </Badge>
            }
            value={formatMoney(current_month_debt)}
            detail={
              <span className="text-foreground font-semibold">
                {`| ${mealsUsed}`}
              </span>
            }
            className="bg-muted shadow-none"
            action={
              <div className="grid w-full gap-4">
                {benefit_available > 0 && (
                  <Progress
                    value={Math.min(100, (benefit_used / benefit_available) * 100)}
                    aria-label={t("pages.accounts.index.spending")}
                  />
                )}
                <AdaptableDialogTrigger asChild>
                  <Button
                    className="w-full"
                    disabled={current_month_detail.orders.length === 0}
                    onClick={() => {
                      setLoading(false)
                      setDetail(current_month_detail)
                    }}
                  >
                    {t("pages.accounts.index.view_detail")}
                  </Button>
                </AdaptableDialogTrigger>
              </div>
            }
          />

          <h1 className="text-xl font-bold">
            {" "}
            {t("pages.accounts.index.payments")}{" "}
          </h1>

          <Tabs
            defaultValue={history ? "history" : "pending"}
            className="w-full"
          >
            <TabsList className="w-full">
              <TabsTrigger value="pending">
                {t("pages.accounts.index.pending")}
              </TabsTrigger>
              <TabsTrigger value="history">
                {t("pages.accounts.index.history")}
              </TabsTrigger>
            </TabsList>
            <TabsContent className="grid w-full gap-2" value="pending">
              <Stat
                label={t("pages.accounts.index.pending_payments")}
                badge={
                  <Badge
                    variant="secondary"
                    className="bg-background text-muted-foreground font-normal"
                  >
                    {t("pages.accounts.index.total_debt")}
                  </Badge>
                }
                value={
                  <>
                    {formatMoney(total_debt)}{" "}
                    <span className="text-base">
                      {t("pages.accounts.index.pending_meals", {
                        count: total_meals,
                      })}
                    </span>
                  </>
                }
                className="bg-muted shadow-none"
              />

              {providersJSX}
            </TabsContent>
            <TabsContent className="grid w-full gap-2" value="history">
              {history_accounts.length === 0 ? (
                <p className="text-muted-foreground text-sm">
                  {t("pages.accounts.index.history_empty")}
                </p>
              ) : (
                <>
                  <div className="flex items-center">
                    <span className="text-foreground min-w-0 truncate text-sm font-medium">
                      {t("pages.accounts.index.providers_label")}{" "}
                      <span className="text-muted-foreground font-normal">
                        {filterLabel}
                      </span>
                    </span>
                    <ProviderFilterSheet
                      providers={providers}
                      selectedProviders={activeProviders}
                      onApply={setActiveProviders}
                      selectionMode="single"
                      allProvidersLabel={t(
                        "pages.accounts.index.all_providers",
                      )}
                    />
                  </div>

                  {filteredHistory.length === 0 ? (
                    <p className="text-muted-foreground text-sm">
                      {t("pages.accounts.index.history_filtered_empty")}
                    </p>
                  ) : (
                    filteredHistory.map((account) => (
                      <PaymentHistoryCard
                        key={account.id}
                        account={account}
                        providerName={
                          providers.find(({ id }) => id === account.provider_id)
                            ?.name
                        }
                        setDetail={setDetail}
                        setLoading={setLoading}
                      />
                    ))
                  )}
                </>
              )}
            </TabsContent>
          </Tabs>

          <AdaptableDialogContent className="pt-5">
            {loading ? (
              <Spinner className="mx-auto size-8" />
            ) : (
              <OrdersTable
                orders={detail ? detail.orders : []}
                month={String(detail?.month)}
              />
            )}

            <AdaptableDialogFooter>
              <AdaptableDialogClose asChild>
                <Button>{t("common.close")}</Button>
              </AdaptableDialogClose>
            </AdaptableDialogFooter>
          </AdaptableDialogContent>
        </AdaptableDialog>
      </div>

      <ConsumerMobileNav />
    </AppLayout>
  )
}
