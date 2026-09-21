import { Head } from "@inertiajs/react"
import { CircleCheck } from "lucide-react"
import { useState } from "react"
import type { JSX } from "react"
import { useTranslation } from "react-i18next"

import AccountCard from "@/components/consumer/accounts/account-card"
import OrdersTable from "@/components/consumer/accounts/orders-table"
import { ConsumerMobileNav } from "@/components/consumer/consumer-mobile-nav"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import {
  Sheet,
  SheetClose,
  SheetContent,
  SheetFooter,
} from "@/components/ui/sheet"
import { Spinner } from "@/components/ui/spinner"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { useIsMobile } from "@/hooks/use-mobile"
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
  providers,
  history,
  current_month_debt,
  current_month_ordered,
  total_debt,
  benefit_available,
}: AccountProps) {
  const { t } = useTranslation()
  const isMobile = useIsMobile()

  const [loading, setLoading] = useState(false)
  const [detail, setDetail] = useState<AccountDetail | null>(null)

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
    <Card key={p.id} className="w-full">
      <CardHeader>
        <CardTitle>{p.name}</CardTitle>
      </CardHeader>

      <CardContent className="grid gap-4">
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

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t("pages.accounts.index.payments")} />

      <div className="mx-auto grid w-full max-w-128 gap-6 p-5 pb-24 md:pb-5">
        <h1 className="text-2xl font-bold">
          {" "}
          {t("pages.accounts.index.payments")}{" "}
        </h1>
        <Card className="bg-zinc-50 dark:bg-zinc-900">
          <CardHeader>
            <CardDescription className="flex">
              {t("pages.accounts.index.spending")}
              <Badge variant="outline" className="ml-auto">
                {t("pages.accounts.index.this_month")}
              </Badge>
            </CardDescription>
            <CardTitle>
              ${current_month_debt}
              <span className="text-zinc-500 dark:text-zinc-400">
                {" | "}
                {current_month_ordered}{" de "}{benefit_available}{" "}
                {benefit_available == 1
                  ? t("pages.accounts.show.lunch")
                  : t("pages.accounts.show.lunches")}
              </span>
            </CardTitle>
          </CardHeader>
        </Card>

        <h1 className="text-xl font-bold">
          {" "}
          {t("pages.accounts.index.payments")}{" "}
        </h1>

        <Sheet>
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
              <Card className="bg-zinc-50 dark:bg-zinc-900">
                <CardHeader>
                  <CardDescription className="flex">
                    {t("pages.accounts.index.pending_payments")}
                    <Badge variant="outline" className="ml-auto">
                      {t("pages.accounts.index.total_debt")}
                    </Badge>
                  </CardDescription>
                  <CardTitle>${total_debt}</CardTitle>
                </CardHeader>
              </Card>

              {providersJSX}
            </TabsContent>
            <TabsContent value="history"></TabsContent>
          </Tabs>

          <SheetContent side={isMobile ? "bottom" : "right"} className="pt-8">
            {loading ? (
              <Spinner className="mx-auto size-8" />
            ) : (
              <OrdersTable
                orders={detail ? detail.orders : []}
                month={String(detail?.month)}
                amount={Number(detail?.amount)}
              />
            )}

            <SheetFooter>
              <SheetClose asChild>
                <Button>{t("common.close")}</Button>
              </SheetClose>
            </SheetFooter>
          </SheetContent>
        </Sheet>
      </div>

      <ConsumerMobileNav />
    </AppLayout>
  )
}
