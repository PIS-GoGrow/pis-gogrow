import { Download, Eye, FileText } from "lucide-react"
import { useTranslation } from "react-i18next"

import StatusBadge from "@/components/status-badge"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible"
import { SheetTrigger } from "@/components/ui/sheet"
import { formatMoney } from "@/lib/money"
import { paymentPresentationStatus } from "@/lib/payment-rejection-reasons"
import { consumerAccounts } from "@/routes"
import type { Account, SimplifiedOrder } from "@/types"

interface AccountDetail {
  orders: SimplifiedOrder[]
  month: string
  amount: number
}

interface PaymentHistoryCardProps {
  account: Account
  providerName?: string
  setDetail: React.Dispatch<React.SetStateAction<AccountDetail | null>>
  setLoading: React.Dispatch<React.SetStateAction<boolean>>
}

export default function PaymentHistoryCard({
  account,
  providerName,
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
    <Card className="bg-background gap-4 rounded-lg p-4 shadow-none">
      <div className="flex flex-col gap-1.5">
        <div className="text-muted-foreground flex items-center justify-between text-sm font-medium">
          <span>{account.due_date}</span>
          <StatusBadge
            kind="payment"
            status="approved"
            label={t("pages.accounts.show.status_accepted")}
          />
        </div>

        <p className="text-foreground text-base font-semibold">
          {providerName ? `${providerName}: ${account.month}` : account.month}
        </p>
      </div>

      <div className="border-border flex items-center justify-between border-y py-3">
        <span className="text-foreground text-base font-semibold">
          {formatMoney(account.orders_price_sum ?? 0)}
          <span className="text-muted-foreground font-normal">
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
            className="text-foreground h-auto p-0 text-sm font-semibold hover:bg-transparent has-[>svg]:px-0 dark:hover:bg-transparent"
            variant="ghost"
          >
            <Eye aria-hidden="true" className="size-4" />{" "}
            {t("pages.accounts.show.see_detail")}
          </Button>
        </SheetTrigger>
      </div>

      {receipts.length > 1 ? (
        <Collapsible className="grid gap-2">
          <CollapsibleTrigger asChild>
            <Button
              variant="secondary"
              className="h-10 w-full rounded-[10px] font-medium"
            >
              <Eye aria-hidden="true" className="size-4" />
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
                  <StatusBadge
                    kind="payment"
                    status={paymentPresentationStatus(payment)}
                    label={
                      paymentPresentationStatus(payment) === "approved"
                        ? t("pages.accounts.show.status_accepted")
                        : undefined
                    }
                  />
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
          className="h-10 w-full rounded-[10px] font-medium"
          asChild
        >
          <a href={receipts[0].receipt_url} download>
            <Download aria-hidden="true" className="size-4" />{" "}
            {t("pages.accounts.show.download_receipt")}
          </a>
        </Button>
      ) : (
        <Button
          variant="secondary"
          className="h-10 w-full rounded-[10px] font-medium"
          disabled
        >
          <Download aria-hidden="true" className="size-4" />{" "}
          {t("pages.accounts.show.download_receipt")}
        </Button>
      )}
    </Card>
  )
}
