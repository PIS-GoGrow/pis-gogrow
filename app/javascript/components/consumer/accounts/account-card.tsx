import { CircleX, Eye, TriangleAlert } from "lucide-react"
import { useTranslation } from "react-i18next"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { useFormatters } from "@/hooks/use-formatters"
import { PARTIAL_PAYMENT_REJECTION_REASON } from "@/lib/payment-rejection-reasons"
import { cn } from "@/lib/utils"
import { consumerAccounts } from "@/routes"
import type { Account, SimplifiedOrder } from "@/types"

import PaymentReceiptDialog from "./payment-receipt-dialog"

interface AccountDetail {
  orders: SimplifiedOrder[]
  month: string
  amount: number
}

interface AccountCardProps {
  account: Account
  setDetail: React.Dispatch<React.SetStateAction<AccountDetail | null>>
  setLoading: React.Dispatch<React.SetStateAction<boolean>>
  onOpenDetail?: () => void
}

export default function AccountCard({
  account,
  setDetail,
  setLoading,
  onOpenDetail,
}: AccountCardProps) {
  const { t } = useTranslation()
  const { formatMoneyShort } = useFormatters()
  const payment =
    [...account.payments]
      .sort(
        (first, second) =>
          new Date(second.created_at).getTime() -
          new Date(first.created_at).getTime(),
      )
      .find(({ status }) => status !== "approved") ??
    account.payments.find(({ status }) => status === "approved")
  const showReceiptSection =
    !account.current || account.payments.some(({ receipt_url }) => receipt_url)

  // Sin comprobante todavía = pendiente; el mismo estado "submitted" cubre
  // tanto el primer envío como un reenvío luego de un rechazo.
  const statusLabel =
    payment?.status === "rejected"
      ? t("pages.accounts.show.status_rejected")
      : payment?.status === "submitted"
        ? t("pages.accounts.show.status_submitted")
        : t("pages.accounts.show.status_pending")

  const statusBadgeClassName =
    payment?.status === "rejected"
      ? "bg-red-100 text-red-700 dark:bg-red-950 dark:text-red-400"
      : payment?.status === "submitted"
        ? "bg-blue-100 text-blue-700 dark:bg-blue-950 dark:text-blue-400"
        : "bg-zinc-200 text-zinc-700 dark:bg-zinc-800 dark:text-zinc-300"

  async function handleClick() {
    setLoading(true)
    onOpenDetail?.()
    try {
      const response = await fetch(consumerAccounts.show(account.id).url, {
        headers: { Accept: "application/json" },
      })

      if (!response.ok) {
        throw new Error(`Error ${response.status}`)
      }

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
        <div className="flex items-center gap-2">
          <span className="text-muted-foreground text-sm font-medium">
            {account.month}
          </span>
          <Badge
            className={cn(
              "border-0 px-2.5 py-0.5 text-xs font-medium",
              statusBadgeClassName,
            )}
          >
            {statusLabel}
          </Badge>
        </div>

        <Badge
          variant="ghost"
          className={cn(
            "ml-auto gap-1 border-0 px-2.5 py-0.5 text-xs font-medium",
            account.due_date_passed
              ? "bg-red-50 text-red-700 dark:bg-red-950 dark:text-red-300"
              : "bg-amber-50 text-amber-700 dark:bg-amber-950 dark:text-amber-300",
          )}
        >
          <TriangleAlert className="size-3.5" />
          {t("pages.accounts.show.due") + account.due_date}
        </Badge>
      </div>

      <div className="border-border flex items-center justify-between border-y py-2.5">
        <span className="text-foreground text-base font-semibold">
          {formatMoneyShort(account.amount ?? 0)}
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
            void handleClick()
          }}
          className="text-foreground ml-auto h-auto gap-1.5 p-0 text-sm font-semibold hover:bg-transparent hover:underline"
          variant="ghost"
        >
          <Eye aria-hidden="true" className="size-4" />
          {t("pages.accounts.show.see_detail")}
        </Button>
      </div>

      {payment?.status === "rejected" &&
        (payment.rejection_reason === PARTIAL_PAYMENT_REJECTION_REASON ? (
          <div className="flex items-start gap-2 rounded-md bg-amber-50 p-3 text-sm text-amber-700 dark:bg-amber-950 dark:text-amber-400">
            <TriangleAlert className="mt-0.5 size-4 shrink-0" />
            <p>{t("pages.accounts.show.partial_payment_warning")}</p>
          </div>
        ) : (
          <div className="flex items-start gap-2 rounded-md bg-red-50 p-3 text-sm text-red-700 dark:bg-red-950 dark:text-red-400">
            <CircleX className="mt-0.5 size-4 shrink-0" />
            <p>
              <span className="font-medium">
                {t("pages.accounts.show.status_rejected")}:
              </span>{" "}
              {payment.rejection_reason}
            </p>
          </div>
        ))}

      {showReceiptSection && (
        <PaymentReceiptDialog
          accountId={account.id}
          canUpload={!account.current}
          payments={[...account.payments].sort(
            (first, second) =>
              new Date(second.created_at).getTime() -
              new Date(first.created_at).getTime(),
          )}
        />
      )}
    </div>
  )
}
