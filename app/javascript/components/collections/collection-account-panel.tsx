import { TriangleAlert } from "lucide-react"
import type { ReactNode } from "react"
import { useTranslation } from "react-i18next"

import CollectionAccountDetailDialog from "@/components/collections/collection-account-detail-dialog"
import CollectionPaymentHistory from "@/components/collections/collection-payment-history"
import PaymentReviewSheet from "@/components/payments/payment-review-sheet"
import { Button } from "@/components/ui/button"
import { Separator } from "@/components/ui/separator"
import { SheetTrigger } from "@/components/ui/sheet"
import { useFormatters } from "@/hooks/use-formatters"
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
}

export default function CollectionAccountPanel({
  account,
  heading = "month",
  aside,
  children,
  showPaymentHistory = false,
  showDownloadAll = false,
}: CollectionAccountPanelProps) {
  const { t } = useTranslation()
  const { formatMoney } = useFormatters()

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
                <span className="flex items-center gap-1.5 text-xs text-red-600 dark:text-red-400">
                  <TriangleAlert className="size-3.5" aria-hidden="true" />
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
        <p>
          <strong className="text-lg">{formatMoney(account.amount)}</strong>
          <span className="text-muted-foreground">
            {" | "}
            {t("pages.provider_collections.meals", { count: account.meals })}
          </span>
        </p>

        <CollectionAccountDetailDialog account={account} />
      </div>

      {account.status === "submitted" && account.payment_id && (
        <PaymentReviewSheet
          paymentId={account.payment_id}
          receiptUrl={account.receipt_url ?? ""}
          contentType={account.receipt_content_type}
          filename={account.owner_name}
        >
          <SheetTrigger asChild>
            <Button className="w-full">Revisar pago</Button>
          </SheetTrigger>
        </PaymentReviewSheet>
      )}
      {showPaymentHistory && (
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
