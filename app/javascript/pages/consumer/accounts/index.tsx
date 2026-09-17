import { Head } from "@inertiajs/react"

import { Button } from "@/components/ui/button"
import { Card, CardTitle, CardHeader, CardDescription, CardContent } from "@/components/ui/card"
import {
  Empty,
  EmptyContent,
  EmptyDescription,
  EmptyHeader,
  EmptyTitle,
} from "@/components/ui/empty"
import AppLayout from "@/layouts/app-layout"
import { consumerAccounts } from "@/routes"
import type { Account, Provider, BreadcrumbItem } from "@/types"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
interface AccountProps {
  accounts: Account[]
  providers: Provider[]
  history: boolean
  current_month_spending: number
}

function AccountCard({ account }: { account: Account }) {
  return (
    <Card className="bg-gray-50">
      <CardHeader>
        <CardTitle>{account.month}</CardTitle>
        <CardDescription>${account.amount}</CardDescription>
      </CardHeader>
    </Card>
  )
}

export default function Index({ accounts, providers, history, current_month_spending }: AccountProps) {
  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: "Pagos",
      href: consumerAccounts.index().url,
    },
  ]

  const accountsJSX: Record<string | number, JSX.Element[]> = {};

  accounts.forEach((account: Account) => {
    const providerId = account.provider_id;

    if (!accountsJSX[providerId]) {
      accountsJSX[providerId] = [];
    }

    accountsJSX[providerId].push(
      <AccountCard key={account.id} account={account} />
    );
  });

  console.log(providers);

  const providersJSX = providers.map(p => {
    (
      <Card key={p.id}>
        <CardHeader>
          <CardTitle>{p.name}</CardTitle>
          <CardDescription>${current_month_spending}</CardDescription>
        </CardHeader>

        <CardContent>
          {accountsJSX[p.id]}
        </CardContent>
      </Card>
    )
  })

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title="Pagos" />

      <div className="mx-auto grid w-full max-w-150 gap-2 p-5">
        <h1> Pagos </h1>
        <Card className="bg-gray-50">
          <CardHeader>
            <CardTitle>Tu Consumo</CardTitle>
            <CardDescription>${current_month_spending}</CardDescription>
          </CardHeader>
        </Card>

        <h1> Pagos </h1>

        <Tabs defaultValue="pending" className="w-[400px]">
          <TabsList>
            <TabsTrigger value="pending">Pendientes</TabsTrigger>
            <TabsTrigger value="history">Historia</TabsTrigger>
          </TabsList>
          <TabsContent value="pending">
            {providersJSX}
          </TabsContent>
          <TabsContent value="history">
            Change your password here.
          </TabsContent>
        </Tabs>
      </div>
    </AppLayout>
  )
}
