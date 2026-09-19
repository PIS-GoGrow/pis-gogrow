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
  Sheet,
  SheetClose,
  SheetContent,
  SheetDescription,
  SheetFooter,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet"
import { consumerAccounts } from "@/routes"

export default function AccountCard({ account, setDetail, setLoading }) {
  async function handleClick() {
    setLoading(true)
    try {
      const response = await fetch(consumerAccounts.show(account.id).url, {
        headers: { Accept: "application/json" },
      })

      if (!response.ok) {
        throw new Error(`Error ${response.status}`)
      }

      const data = await response.json()
      setDetail(data)
    } catch (err) {
      console.error(err)
    } finally {
      setLoading(false)
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
            ${account.orders_price_sum}
            <span className="text-zinc-500 dark:text-zinc-400">
              {" | "}
              {account.orders_amount_sum}{" "}
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
