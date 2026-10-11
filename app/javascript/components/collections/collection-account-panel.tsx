import { Link } from "@inertiajs/react"
import { CircleCheck, Eye, TriangleAlert } from "lucide-react"
import type { ReactNode } from "react"
import { useTranslation } from "react-i18next"

import { AdaptableDialogTrigger } from "@/components/adaptable-dialog"
import CollectionAccountDetailDialog from "@/components/collections/collection-account-detail-dialog"
import CollectionPaymentHistory from "@/components/collections/collection-payment-history"
import DebtReminderDialog from "@/components/collections/debt-reminder-dialog"
import PaymentReviewSheet from "@/components/payments/payment-review-sheet"
import { Button, buttonVariants } from "@/components/ui/button"
import { Separator } from "@/components/ui/separator"
import { useFormatters } from "@/hooks/use-formatters"
import { cn } from "@/lib/utils"
import { providerCollections } from "@/routes"
import type { ProviderCollectionAccount } from "@/types"

interface CollectionAccountPanelProps {
  account: ProviderCollectionAccount
  // Qué encabeza el recuadro: el mes con su vencimiento mientras se espera el
  // cobro, la fecha de pago una vez cobrado, o nada si la fila ya la muestra.
  heading?: "month" | "paid_on" | "none"
  // Reemplaza al vencimiento en el encabezado del mes.
  aside?: ReactNode
  children?: ReactNode
  showPaymentHistory?: boolean
  showDownloadAll?: boolean
  settled?: boolean
  detailMode?: "dialog" | "link"
}

export default function CollectionAccountPanel({
  account,
  heading = "month",
  aside,
  children,
  showPaymentHistory = false,
  showDownloadAll = false,
  settled = false,
  detailMode = "dialog",
}: CollectionAccountPanelProps) {
  const { t } = useTranslation()
  const { formatMoney } = useFormatters()
  const reminder = account.debt_reminder

  return (
    <div className="bg-muted/60 grid gap-3 rounded-lg p-3">
      {heading === "paid_on" && (
        <>
          <span className="text-muted-foreground text-sm">
            {account.paid_on}
          </span>
          <Separator />
        </>
      )}

      {heading === "month" && (
        <>
          <div className="flex flex-wrap items-center justify-between gap-2 text-sm">
            <span className="text-muted-foreground">{account.month}</span>
            {aside ??
              (account.status !== "approved" && (
                <span
                  className={cn(
                    "flex items-center gap-1.5 text-sm font-medium",
                    account.overdue
                      ? "text-red-700 dark:text-red-400"
                      : "text-muted-foreground",
                  )}
                >
                  {account.overdue && (
                    <TriangleAlert className="size-4" aria-hidden="true" />
                  )}
                  {t("pages.provider_collections.group.due", {
                    date: account.due_date,
                  })}
                </span>
              ))}
          </div>
          <Separator />
        </>
      )}

      <div className="flex flex-wrap items-center justify-between gap-2">
        <p className="text-foreground text-base font-semibold">
          {formatMoney(account.amount)}
          <span className="text-muted-foreground font-normal">
            {" | "}
            {t("pages.provider_collections.meals", { count: account.meals })}
          </span>
        </p>

        {detailMode === "dialog" ? (
          <CollectionAccountDetailDialog account={account} settled={settled} />
        ) : (
          <Link
            href={providerCollections.show(account.id)}
            className={cn(
              buttonVariants({ variant: "ghost", size: "sm" }),
              "-mr-2.5 text-sm font-semibold",
            )}
          >
            <Eye aria-hidden="true" />
            {t("pages.provider_collections.group.detail")}
          </Link>
        )}
      </div>

      {account.status === "submitted" && account.payment_id && (
        <PaymentReviewSheet
          paymentId={account.payment_id}
          receiptUrl={account.receipt_url ?? ""}
          contentType={account.receipt_content_type}
          filename={account.owner_name}
          expectedAmount={account.amount}
          canApprove={account.can_approve_payment}
        >
          <AdaptableDialogTrigger asChild>
            <Button className="h-10 w-full rounded-[10px]">Revisar pago</Button>
          </AdaptableDialogTrigger>
        </PaymentReviewSheet>
      )}
      {(reminder.eligible ||
        reminder.blocked_reason === "cooldown" ||
        reminder.blocked_reason === "limit_reached") && (
        <DebtReminderDialog
          accountId={account.id}
          eligible={reminder.eligible}
          employeeName={account.owner_name}
          month={account.month}
          amount={account.amount}
        />
      )}
      {reminder.blocked_reason === "cooldown" && (
        <p className="text-muted-foreground flex items-center gap-2 text-sm">
          <CircleCheck className="size-4" aria-hidden="true" />
          {t("pages.provider_collections.reminder.next_available", {
            date: reminder.next_available_at,
          })}
        </p>
      )}
      {reminder.blocked_reason === "limit_reached" && (
        <p className="text-muted-foreground text-sm">
          {t("pages.provider_collections.reminder.limit_reached")}
        </p>
      )}
      {(showPaymentHistory || account.status === "rejected") && (
        <CollectionPaymentHistory
          payments={account.payments}
          showDownloadAll={showDownloadAll}
        />
      )}

      {children && (
        <>
          <Separator />
          {children}
        </>
      )}
    </div>
  )
}
