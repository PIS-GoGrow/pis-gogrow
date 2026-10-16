import { Download, Eye, FileText } from "lucide-react"
import { useTranslation } from "react-i18next"

import StatusBadge from "@/components/status-badge"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible"
import { useFormatters } from "@/hooks/use-formatters"
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
  onOpenDetail?: () => void
}

export default function PaymentHistoryCard({
  account,
  setDetail,
  setLoading,
  onOpenDetail,
}: PaymentHistoryCardProps) {
  const { t } = useTranslation()
  const { formatMoneyShort } = useFormatters()

  const receipts = [...account.payments]
    .filter((payment) => Boolean(payment.receipt_url))
    .sort(
      (a, b) =>
        new Date(b.created_at).getTime() - new Date(a.created_at).getTime(),
    )

  async function handleSeeDetail() {
    setLoading(true)
    onOpenDetail?.()
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
    <div className="border-border bg-muted space-y-3 rounded-lg border p-4">
      <div className="flex items-center justify-between">
        <span className="text-muted-foreground text-sm font-medium">
          {account.month}
        </span>
        <span className="inline-flex items-center gap-1.5 rounded-full border-0 bg-green-50 px-2.5 py-0.5 text-xs font-medium text-green-700 dark:bg-green-950 dark:text-green-300">
          <span className="size-1.5 rounded-full bg-green-500" />
          {t("pages.accounts.show.status_accepted")}
        </span>
      </div>

      <div className="border-border flex items-center justify-between border-y py-2.5">
        <span className="text-foreground text-base font-semibold">
          {formatMoneyShort(account.orders_price_sum)}
          <span className="text-foreground font-semibold">
            {" | "}
            {account.orders_amount_sum}{" "}
            {account.orders_amount_sum == 1
              ? t("pages.accounts.show.lunch")
              : t("pages.accounts.show.lunches")}
          </span>
        </span>

        <Button
          type="button"
          onClick={() => {
            void handleSeeDetail()
          }}
          className="text-foreground ml-auto h-auto gap-1.5 p-0 text-sm font-semibold hover:bg-transparent hover:underline"
          variant="ghost"
        >
          <Eye aria-hidden="true" className="size-4" />
          {t("pages.accounts.show.see_detail")}
        </Button>
      </div>

      {receipts.length > 1 ? (
        <Collapsible className="grid gap-2">
          <CollapsibleTrigger asChild>
            <Button
              variant="secondary"
              className="border-border h-10 rounded-[10px] border text-sm font-medium"
            >
              <Eye aria-hidden="true" />
              {t("pages.accounts.show.see_receipts")}
            </Button>
          </CollapsibleTrigger>
          <CollapsibleContent className="grid gap-2 pt-1">
            {receipts.map((payment) => (
              <div
                key={payment.id}
                className="bg-background border-border grid min-w-0 gap-2 rounded-md border p-3 text-sm"
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
                        className="gap-1.5 border-0 bg-amber-50 px-2.5 py-1 text-amber-700 dark:bg-amber-950 dark:text-amber-300 [&>span]:bg-amber-500"
                      >
                        <span className="size-1.5 rounded-full" />
                        {t("pages.provider_collections.partial_payment_badge")}
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
        <Button
          variant="secondary"
          className="border-border h-10 rounded-[10px] border text-sm font-medium"
          asChild
        >
          <a href={receipts[0].receipt_url} download>
            <Download aria-hidden="true" />{" "}
            {t("pages.accounts.show.download_receipt")}
          </a>
        </Button>
      ) : (
        <Button
          variant="secondary"
          className="border-border h-10 rounded-[10px] border text-sm font-medium"
          disabled
        >
          <Download aria-hidden="true" />{" "}
          {t("pages.accounts.show.download_receipt")}
        </Button>
      )}
    </div>
  )
}
