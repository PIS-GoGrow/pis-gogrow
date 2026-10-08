import { Download, Eye, FileText } from "lucide-react"
import { useTranslation } from "react-i18next"

import StatusBadge from "@/components/status-badge"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import {
  Card,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible"
import { Separator } from "@/components/ui/separator"
import { SheetTrigger } from "@/components/ui/sheet"
import { PARTIAL_PAYMENT_REJECTION_REASON } from "@/lib/payment-rejection-reasons"
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

  const receipts = [...account.payments]
    .filter((payment) => Boolean(payment.receipt_url))
    .sort(
      (a, b) =>
        new Date(b.created_at).getTime() - new Date(a.created_at).getTime(),
    )

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
              <Eye aria-hidden="true" /> {t("pages.accounts.show.see_detail")}
            </Button>
          </SheetTrigger>
        </CardTitle>

        <Separator />

        {receipts.length > 1 ? (
          <Collapsible className="grid gap-2">
            <CollapsibleTrigger asChild>
              <Button variant="outline">
                <Eye aria-hidden="true" />
                {t("pages.accounts.show.see_receipts")}
              </Button>
            </CollapsibleTrigger>
            <CollapsibleContent className="grid gap-2 pt-1">
              {receipts.map((payment) => (
                <div
                  key={payment.id}
                  className="bg-background grid min-w-0 gap-2 rounded-md border p-3 text-sm"
                >
                  <div className="text-muted-foreground flex items-center justify-between gap-2 text-xs">
                    <span>
                      {t("pages.accounts.show.receipt_sent_at", {
                        date: payment.receipt_uploaded_at,
                      })}
                    </span>
                    <div className="flex shrink-0 items-center gap-1.5">
                      {payment.rejection_reason ===
                        PARTIAL_PAYMENT_REJECTION_REASON && (
                        <Badge
                          variant="outline"
                          className="gap-1.5 border-amber-200 bg-amber-50 px-2.5 py-1 text-amber-700 dark:border-amber-900 dark:bg-amber-950 dark:text-amber-300 [&>span]:bg-amber-500"
                        >
                          <span className="size-1.5 rounded-full" />
                          {t(
                            "pages.provider_collections.partial_payment_badge",
                          )}
                        </Badge>
                      )}
                      <StatusBadge kind="payment" status={payment.status} />
                    </div>
                  </div>

                  <div className="flex min-w-0 items-center gap-2">
                    <FileText aria-hidden="true" className="size-4 shrink-0" />
                    <a
                      className="block min-w-0 flex-1 overflow-hidden font-medium text-ellipsis whitespace-nowrap hover:underline"
                      href={payment.receipt_url}
                      download
                    >
                      {payment.receipt_filename}
                    </a>
                    <Button asChild size="icon-sm" variant="ghost">
                      <a
                        href={payment.receipt_url}
                        download
                        aria-label={`Descargar ${payment.receipt_filename ?? "comprobante"}`}
                      >
                        <Download aria-hidden="true" />
                      </a>
                    </Button>
                  </div>
                </div>
              ))}
            </CollapsibleContent>
          </Collapsible>
        ) : receipts.length === 1 ? (
          <Button variant="outline" asChild>
            <a href={receipts[0].receipt_url} download>
              <Download aria-hidden="true" />{" "}
              {t("pages.accounts.show.download_receipt")}
            </a>
          </Button>
        ) : (
          <Button variant="outline" disabled>
            <Download aria-hidden="true" />{" "}
            {t("pages.accounts.show.download_receipt")}
          </Button>
        )}
      </CardHeader>
    </Card>
  )
}
