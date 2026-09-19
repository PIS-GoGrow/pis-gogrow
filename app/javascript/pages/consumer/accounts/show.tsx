import { Head } from "@inertiajs/react"

import {
  Table,
  TableBody,
  TableCell,
  TableFooter,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"

import AppLayout from "@/layouts/app-layout"
import { consumerAccounts } from "@/routes"
import type { BreadcrumbItem, SimplifiedOrder } from "@/types"
import OrdersTable from "@/components/consumer/accounts/orders-table"

interface AccountProps {
  orders: SimplifiedOrder[]
  month: string
  amount: number
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
      <Head title={"Consumos " + month} />

      <OrdersTable orders={orders} month={month} amount={amount} />
    </AppLayout>
  )
}
