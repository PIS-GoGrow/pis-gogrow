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
import type { Account, BreadcrumbItem, Provider } from "@/types"

interface AccountProps {
  orders: Order[]
}

function OrderRow({ order }: { order: Order }) {
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

export default function Show({ orders }: AccountProps) {
  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: "Pagos",
      href: consumerAccounts.index().url,
    },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>

    <Table>
      <TableCaption>A list of your recent invoices.</TableCaption>
      <TableHeader>
        <TableRow>
          <TableHead className="w-[100px]">Invoice</TableHead>
          <TableHead>Status</TableHead>
          <TableHead>Method</TableHead>
          <TableHead className="text-right">Amount</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody> 
              
      </TableBody>
      <TableFooter>
        <TableRow>
          <TableCell colSpan={3}>Total</TableCell>
          <TableCell className="text-right">$2,500.00</TableCell>
        </TableRow>
      </TableFooter>
    </Table>

    </AppLayout>
  )
}
