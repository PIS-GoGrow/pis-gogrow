import { Head } from "@inertiajs/react"
import { CircleCheck } from "lucide-react"
import { useState } from "react"

import AccountCard from "@/components/consumer/accounts/account-card"
import OrdersTable from "@/components/consumer/accounts/orders-table"
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
import type { Account, BreadcrumbItem, Provider } from "@/types"

interface AccountProps {
  accounts: Account[]
  providers: Provider[]
  history: boolean
  current_month_spending: number
  total_debt: number
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
  current_month_spending,
  total_debt,
}: AccountProps) {
  const isMobile = useIsMobile()
  const [loading, setLoading] = useState(false)
  const [detail, setDetail] = useState<AccountDetail | null>(null)

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: "Pagos",
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
            <CircleCheck className="mr-2" size={16} /> ¡Sin deudas pendientes
            con este proveedor!
          </div>
        )}
      </CardContent>
    </Card>
  ))

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title="Pagos" />

      <div className="mx-auto grid w-full max-w-128 gap-6 p-5">
        <h1 className="text-2xl font-bold"> Pagos </h1>
        <Card className="bg-zinc-50 dark:bg-zinc-900">
          <CardHeader>
            <CardDescription className="flex">
              Tu Consumo
              <Badge variant="outline" className="ml-auto">
                Este mes
              </Badge>
            </CardDescription>
            <CardTitle>${current_month_spending}</CardTitle>
          </CardHeader>
        </Card>

        <h1 className="text-xl font-bold"> Pagos </h1>

        <Sheet>
          <Tabs
            defaultValue={history ? "history" : "pending"}
            className="w-full"
          >
            <TabsList className="w-full">
              <TabsTrigger value="pending">Pendientes</TabsTrigger>
              <TabsTrigger value="history">Historial</TabsTrigger>
            </TabsList>
            <TabsContent className="grid w-full gap-2" value="pending">
              <Card className="bg-zinc-50 dark:bg-zinc-900">
                <CardHeader>
                  <CardDescription className="flex">
                    Pagos pendientes
                    <Badge variant="outline" className="ml-auto">
                      Deuda total
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
                orders={detail?.orders}
                month={detail?.month}
                amount={detail?.amount}
              />
            )}

            <SheetFooter>
              <SheetClose asChild>
                <Button>Cerrar</Button>
              </SheetClose>
            </SheetFooter>
          </SheetContent>
        </Sheet>
      </div>
    </AppLayout>
  )
}
