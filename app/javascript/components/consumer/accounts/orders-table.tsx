import {
  Table,
  TableBody,
  TableCell,
  TableFooter,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import type { SimplifiedOrder } from "@/types"

interface AccountProps {
  orders: SimplifiedOrder[]
  month: string
  amount: number
}

function truncate(text: string, maxLength = 20): string {
  if (text.length <= maxLength) return text
  return text.slice(0, maxLength) + "..."
}

export default function OrdersTable({ orders, month, amount }: AccountProps) {
  if (!orders) return

  return (
    <div className="mx-auto mt-2 max-w-100">
      <h1 className="text-l mb-2 font-bold">Consumos {month}</h1>

      <div className="overflow-hidden rounded-md border">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Fecha</TableHead>
              <TableHead>Plato</TableHead>
              <TableHead>Cant.</TableHead>
              <TableHead className="text-right">Monto</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {orders.map((order) => (
              <TableRow key={order.id}>
                <TableCell>{order.date}</TableCell>
                <TableCell>{truncate(order.menu_name)}</TableCell>
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
