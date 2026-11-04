import { Download, Eye, TriangleAlert } from "lucide-react"
import { useTranslation } from "react-i18next"

import PaymentReceiptDialog from "@/components/consumer/accounts/payment-receipt-dialog"
import StatusBadge from "@/components/status-badge"
import { Button } from "@/components/ui/button"
import {
  Card,
  CardAction,
  CardContent,
  CardDescription,
  CardHeader,
} from "@/components/ui/card"
import { useFormatters } from "@/hooks/use-formatters"
import { cn } from "@/lib/utils"
import { adminPayments } from "@/routes"
import type { AdminAccount } from "@/types"

interface PeriodCardProps {
  account: AdminAccount
  // En el historial los períodos van todos juntos, así que cada tarjeta dice
  // de qué proveedor es.
  providerName?: string
  paymentDetailsMissing?: boolean
  onOpenDetail: () => void
}

export default function PeriodCard({
  account,
  providerName,
  paymentDetailsMissing = false,
  onOpenDetail,
}: PeriodCardProps) {
  const { t } = useTranslation()
  const { formatMoney } = useFormatters()

  const status = account.collection_status
  const title = providerName
    ? `${providerName}: ${account.month}`
    : account.month

  if (status === "approved") {
    return (
      <Card className="bg-background gap-4 rounded-lg p-4 shadow-none">
        <div className="flex flex-col gap-1.5">
          <div className="text-muted-foreground flex items-center justify-between text-sm font-medium">
            <span>{account.paid_on}</span>
            <StatusBadge
              status={status}
              kind="payment"
              label={t("pages.admin.payments.index.confirmed")}
            />
          </div>
          <p className="text-foreground text-base font-semibold">{title}</p>
        </div>

        <div className="border-border flex flex-col gap-3 border-y py-3">
          <span className="text-muted-foreground text-sm font-medium">
            {t("pages.admin.payments.index.total_paid")}
          </span>
          <div className="flex items-center justify-between">
            <span className="text-foreground text-base font-semibold">
              {formatMoney(account.payable_amount)}
            </span>
            <Button
              variant="ghost"
              onClick={onOpenDetail}
              className="text-foreground h-auto p-0 text-sm font-semibold hover:bg-transparent has-[>svg]:px-0 dark:hover:bg-transparent"
            >
              <Eye aria-hidden="true" className="size-4" />
              {t("pages.admin.payments.index.see_detail")}
            </Button>
          </div>
        </div>

        {account.invoice_download_url && (
          <Button className="h-10 w-full rounded-[10px] font-medium" asChild>
            <a href={account.invoice_download_url}>
              <Download aria-hidden="true" className="size-4" />
              {t("pages.admin.payments.index.download_invoice")}
            </a>
          </Button>
        )}
        {account.receipt_download_url && (
          <Button
            variant="secondary"
            className="h-10 w-full rounded-[10px] font-medium"
            asChild
          >
            <a href={account.receipt_download_url} download>
              <Download aria-hidden="true" className="size-4" />
              {t("pages.admin.payments.index.download_receipt")}
            </a>
          </Button>
        )}
      </Card>
    )
  }

  return (
    <Card className="bg-muted/50 gap-3 py-4">
      <CardHeader className="px-4">
        <CardDescription>
          {providerName ? (
            <span className="text-foreground font-semibold">{title}</span>
          ) : (
            account.month
          )}
        </CardDescription>
        <CardAction className="flex flex-wrap items-center justify-end gap-2">
          <span
            className={cn(
              "flex items-center gap-1.5 text-xs",
              account.due_date_passed
                ? "text-red-600 dark:text-red-400"
                : "text-amber-600 dark:text-amber-400",
            )}
          >
            <TriangleAlert className="size-3.5" aria-hidden="true" />
            {t("pages.admin.payments.index.due", { date: account.due_date })}
          </span>
          <StatusBadge status={status} kind="payment" />
        </CardAction>
      </CardHeader>

      <CardContent className="grid gap-2 px-4">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <p className="flex flex-wrap items-baseline gap-x-2">
            {/* El monto es un decimal de Rails, así que viaja como texto. */}
            <strong>{formatMoney(account.payable_amount)}</strong>
            <span className="text-muted-foreground text-sm">
              {"| "}
              {t("pages.admin.payments.index.meals", {
                count: account.orders_amount_sum,
              })}
            </span>
          </p>

          <Button variant="ghost" size="sm" onClick={onOpenDetail}>
            <Eye aria-hidden="true" />
            {t("pages.admin.payments.index.see_detail")}
          </Button>
        </div>

        <PaymentReceiptDialog
          accountId={account.id}
          uploadDisabled={
            paymentDetailsMissing ||
            account.payments.some(({ status }) => status === "submitted")
          }
          uploadDisabledHint={
            paymentDetailsMissing
              ? t("pages.admin.payments.index.bank.missing_upload_hint")
              : undefined
          }
          createAction={adminPayments.create()}
          destroyAction={adminPayments.destroy}
          payments={account.payments}
        />
      </CardContent>
    </Card>
  )
}
