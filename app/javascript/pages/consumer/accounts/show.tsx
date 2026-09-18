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
import AppLayout from "@/layouts/app-layout"
import { consumerAccounts } from "@/routes"
import type { SimplifiedOrder, BreadcrumbItem } from "@/types"

interface AccountProps {
  orders: SimplifiedOrder[]
  month: string
  amount: number
}

function OrdersTable({ orders, month, amount }: AccountProps) {
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

export default function Show({ orders, month, amount }: AccountProps) {
  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: "Pagos",
      href: consumerAccounts.index().url,
    },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <OrdersTable orders={orders} month={month} amount={amount} />
    </AppLayout>
  )
}
