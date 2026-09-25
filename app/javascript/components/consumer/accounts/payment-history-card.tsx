import { Download, Eye } from "lucide-react"
import { useTranslation } from "react-i18next"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Separator } from "@/components/ui/separator"
import { SheetTrigger } from "@/components/ui/sheet"
import { consumerAccounts } from "@/routes"
import type { Account, SimplifiedOrder } from "@/types"

interface AccountDetail {
  orders: SimplifiedOrder[]
  month: string
  amount: number
}

interface PaymentHistoryCardProps {
  account: Account
  setDetail: React.Dispatch<React.SetStateAction<AccountDetail | null>>
  setLoading: React.Dispatch<React.SetStateAction<boolean>>
}

export default function PaymentHistoryCard({
  account,
  setDetail,
  setLoading,
}: PaymentHistoryCardProps) {
  const { t } = useTranslation()

  // Un Account puede tener varios Payment (ej: uno rechazado y luego uno
  // nuevo); mostramos el estado del más reciente.
  const latestPayment = [...account.payments].sort(
    (a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime(),
  )[0]

  async function handleSeeDetail() {
    setLoading(true)
    try {
      const response = await fetch(consumerAccounts.show(account.id).url, {
        headers: { Accept: "application/json" },
      })
      if (!response.ok) throw new Error(`Error ${response.status}`)
      const data = (await response.json()) as AccountDetail
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
        <CardDescription className="flex items-center">
          {account.month}
          {/* Como es historial los payments estan siempre aprobados */}
          <Badge className="ml-auto bg-green-100 text-green-700 dark:bg-green-950 dark:text-green-400">
            {t("pages.accounts.show.status_accepted")}
          </Badge>
        </CardDescription>

        <Separator />

        <CardTitle className="flex items-center">
          <span>
            ${account.orders_price_sum}
            <span className="text-zinc-500 dark:text-zinc-400">
              {" | "}
              {account.orders_amount_sum}{" "}
              {account.orders_amount_sum == 1
                ? t("pages.accounts.show.lunch")
                : t("pages.accounts.show.lunches")}
            </span>
          </span>

          <SheetTrigger asChild>
            <Button
              onClick={() => {
                void handleSeeDetail()
              }}
              className="ml-auto"
              variant="ghost"
            >
              <Eye /> {t("pages.accounts.show.see_detail")}
            </Button>
          </SheetTrigger>
        </CardTitle>

        <Separator />

        {/* TODO(IBP-019): habilitar cuando Payment tenga el archivo del
            comprobante adjunto; hoy no existe ese campo en el modelo. */}
        <Button variant="outline" disabled>
          <Download /> {t("pages.accounts.show.download_receipt")}
        </Button>
      </CardHeader>
    </Card>
  )
}
