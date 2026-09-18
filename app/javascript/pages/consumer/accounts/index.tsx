import { Head } from "@inertiajs/react"
import { CircleCheck, Eye, TriangleAlert } from "lucide-react"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { Separator } from "@/components/ui/separator"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import AppLayout from "@/layouts/app-layout"
import { consumerAccounts } from "@/routes"
import type { Account, BreadcrumbItem, Provider } from "@/types"

interface AccountProps {
  accounts: Account[]
  providers: Provider[]
  history: boolean
  current_month_spending: number
}

function AccountCard({ account }: { account: Account }) {
  return (
    <Card className="bg-zinc-50 dark:bg-zinc-900">
      <CardHeader className="grid gap-4">
        <CardDescription className="flex">
          {account.month}

          <Badge
            variant="ghost"
            className={
              account.due_date_passed
                ? "ml-auto text-red-600 dark:text-red-400"
                : "ml-auto text-amber-600 dark:text-amber-400"
            }
          >
            <TriangleAlert />
            Vence: {account.due_date}
          </Badge>
        </CardDescription>

        <Separator />

        <CardTitle className="flex items-center">
          <span>
            ${account.amount}
            <span className="text-zinc-500 dark:text-zinc-400">
              {" | "}
              {account.orders_placed}{" "}
              {account.orders_placed == 1 ? "vianda" : "viandas"}
            </span>
          </span>
          <Button className="ml-auto" variant="ghost">
            {" "}
            <Eye /> Ver detalle{" "}
          </Button>
        </CardTitle>

        <Separator />

        <Button> Subir comprobante de pago </Button>
      </CardHeader>
    </Card>
  )
}

export default function Index({
  accounts,
  providers,
  history,
  current_month_spending,
}: AccountProps) {
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
      <AccountCard key={account.id} account={account} />,
    )
  })

  const providersJSX = providers.map((p) => (
    <Card key={p.id} className="w-full">
      <CardHeader>
        <CardTitle>{p.name}</CardTitle>
      </CardHeader>

      <CardContent>
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

      <div className="mx-auto grid w-full max-w-150 gap-2 p-5">
        <h1> Pagos </h1>
        <Card className="bg-zinc-50 dark:bg-zinc-900">
          <CardHeader>
            <CardTitle className="flex">
              Tu Consumo
              <Badge variant="outline" className="ml-auto">
                Este mes
              </Badge>
            </CardTitle>
            <CardDescription>${current_month_spending}</CardDescription>
          </CardHeader>
        </Card>

        <h1> Pagos </h1>

        <Tabs defaultValue={history ? "history" : "pending"} className="w-full">
          <TabsList className="w-full">
            <TabsTrigger value="pending">Pendientes</TabsTrigger>
            <TabsTrigger value="history">Historia</TabsTrigger>
          </TabsList>
          <TabsContent className="grid w-full gap-2" value="pending">
            {providersJSX}
          </TabsContent>
          <TabsContent value="history"></TabsContent>
        </Tabs>
      </div>
    </AppLayout>
  )
}
