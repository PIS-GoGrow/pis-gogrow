import { Eye, TriangleAlert } from "lucide-react"
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
import { SheetTrigger } from "@/components/ui/sheet"
import { useFormatters } from "@/hooks/use-formatters"
import { cn } from "@/lib/utils"
import { adminPayments } from "@/routes"
import type { Account, PaymentStatus } from "@/types"

interface PeriodCardProps {
  account: Account
  // En el historial los períodos van todos juntos, así que cada tarjeta dice
  // de qué proveedor es.
  providerName?: string
  onOpenDetail: () => void
}

// Misma regla que el estado de cobro del servidor: manda el último
// comprobante, y sin comprobantes el período está pendiente.
function statusOf({ payments }: Account): PaymentStatus {
  const last = [...payments].sort(
    (first, second) =>
      new Date(second.created_at).getTime() -
      new Date(first.created_at).getTime(),
  )[0]

  return last?.status ?? "pending"
}

export default function PeriodCard({
  account,
  providerName,
  onOpenDetail,
}: PeriodCardProps) {
  const { t } = useTranslation()
  const { formatMoney } = useFormatters()

  const status = statusOf(account)

  return (
    <Card className="bg-muted/50 gap-3 py-4">
      <CardHeader className="px-4">
        <CardDescription>
          {providerName ? `${providerName}: ${account.month}` : account.month}
        </CardDescription>
        <CardAction>
          <StatusBadge status={status} kind="payment" />
        </CardAction>
      </CardHeader>

      <CardContent className="grid gap-2 px-4">
        <p className="flex flex-wrap items-baseline gap-x-2">
          {/* El monto es un decimal de Rails, así que viaja como texto. */}
          <strong className="text-2xl">
            {formatMoney(Number(account.amount ?? 0))}
          </strong>
          <span className="text-muted-foreground text-sm">
            {"| "}
            {t("pages.admin.payments.index.meals", {
              count: account.orders_amount_sum,
            })}
          </span>
        </p>

        <div className="flex flex-wrap items-center justify-between gap-2">
          {status === "approved" ? (
            <span />
          ) : (
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
          )}

          <SheetTrigger asChild>
            <Button variant="ghost" size="sm" onClick={onOpenDetail}>
              <Eye aria-hidden="true" />
              {t("pages.admin.payments.index.see_detail")}
            </Button>
          </SheetTrigger>
        </div>

        {status !== "approved" && (
          <PaymentReceiptDialog
            accountId={account.id}
            createAction={adminPayments.create()}
            destroyAction={adminPayments.destroy}
            payments={account.payments}
          />
        )}
      </CardContent>
    </Card>
  )
}
