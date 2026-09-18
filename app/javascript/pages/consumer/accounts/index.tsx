import { Head } from "@inertiajs/react"
import { CircleCheck, Eye, TriangleAlert } from "lucide-react"
import { useState } from "react"

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
import {
  Sheet,
  SheetClose,
  SheetContent,
  SheetDescription,
  SheetFooter,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet"
import {
  Table,
  TableBody,
  TableCaption,
  TableCell,
  TableFooter,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"

interface AccountProps {
  accounts: Account[]
  providers: Provider[]
  history: boolean
  current_month_spending: number
}

interface AccountDetail {
  orders: SimplifiedOrder[]
  month: string
  amount: number
}
function OrdersTable({ orders, month, amount }: AccountDetail) {
  if (!orders)
    return

  return (
    <div className="mx-auto mt-2 max-w-150">
      <h1 className="text-l mb-2 font-bold">Consumos {month}</h1>

      <div className="overflow-hidden rounded-md border">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Fecha</TableHead>
              <TableHead>Plato</TableHead>
              <TableHead>Cantidad</TableHead>
              <TableHead className="text-right">Monto</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {orders.map((order) => (
              <TableRow key={order.id}>
                <TableCell>{order.date}</TableCell>
                <TableCell>{order.menu_name}</TableCell>
                <TableCell>{order.amount}</TableCell>
                <TableCell className="text-right">{order.price}</TableCell>
              </TableRow>
            ))}
          </TableBody>
          <TableFooter>
            <TableRow>
              <TableCell colSpan={3}>Total</TableCell>
              <TableCell className="text-right">{amount}</TableCell>
            </TableRow>
          </TableFooter>
        </Table>
      </div>
    </div>
  )
}


function AccountCard({ account, setDetail, setLoading }) {
  async function handleClick() {
    setLoading(true);
    try {
      const response = await fetch(consumerAccounts.show(account.id).url, {
        headers: { Accept: "application/json" },
      });


    if (!response.ok) {
      throw new Error(`Error ${response.status}`);
    }

    const data = await response.json();
    setDetail(data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  }

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
          <SheetTrigger asChild>
            <Button onClick={handleClick} className="ml-auto" variant="ghost">
              {" "}
              <Eye /> Ver detalle{" "}
            </Button>
          </SheetTrigger>
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
  const [loading, setLoading] = useState(false);
  const [detail, setDetail] = useState<AccountDetail | null>(null);

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
      <AccountCard key={account.id} setDetail={setDetail} setLoading={setLoading} account={account} />,
    )
  })

  console.log(detail)

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

        <Sheet>
          <Tabs
            defaultValue={history ? "history" : "pending"}
            className="w-full"
          >
            <TabsList className="w-full">
              <TabsTrigger value="pending">Pendientes</TabsTrigger>
              <TabsTrigger value="history">Historia</TabsTrigger>
            </TabsList>
            <TabsContent className="grid w-full gap-2" value="pending">
              {providersJSX}
            </TabsContent>
            <TabsContent value="history"></TabsContent>
          </Tabs>

          <SheetContent>
            <OrdersTable className="m-2" orders={detail?.orders} month={detail?.month} amount={detail?.amount}/>
            <SheetFooter>
              <Button type="submit">Save changes</Button>
              <SheetClose render={<Button variant="outline">Close</Button>} />
            </SheetFooter>
          </SheetContent>
        </Sheet>
      </div>
    </AppLayout>
  )
}
