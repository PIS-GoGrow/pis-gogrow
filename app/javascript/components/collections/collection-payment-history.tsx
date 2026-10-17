import { Download, FileText } from "lucide-react"
import { useTranslation } from "react-i18next"

import StatusBadge from "@/components/status-badge"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { PARTIAL_PAYMENT_REJECTION_REASON } from "@/lib/payment-rejection-reasons"
import type { ProviderCollectionPayment } from "@/types"

interface CollectionPaymentHistoryProps {
  payments: ProviderCollectionPayment[]
  showDownloadAll?: boolean
}

export default function CollectionPaymentHistory({
  payments,
  showDownloadAll = false,
}: CollectionPaymentHistoryProps) {
  const { t } = useTranslation()
  const receipts = payments.filter((payment) => payment.receipt_url)

  if (receipts.length === 0) return null

  if (receipts.length === 1) {
    const payment = receipts[0]

    return (
      <Button asChild className="h-12 w-full rounded-[10px]">
        <a href={payment.receipt_url ?? undefined} download>
          <Download aria-hidden="true" />
          Descargar comprobante
        </a>
      </Button>
    )
  }

  const list = (
    <div className="grid gap-2">
      {receipts.map((payment) => (
        <div
          key={payment.id}
          className="bg-background grid gap-2 rounded-lg border p-3 text-sm"
        >
          <div className="flex items-center justify-between gap-2">
            <span className="text-muted-foreground text-xs">
              {payment.date}
            </span>
            <div className="flex items-center gap-1.5">
              {payment.rejection_reason ===
                PARTIAL_PAYMENT_REJECTION_REASON && (
                <Badge
                  variant="outline"
                  className="gap-1.5 border-amber-200 bg-amber-50 px-2.5 py-1 text-amber-700 dark:border-amber-900 dark:bg-amber-950 dark:text-amber-300 [&>span]:bg-amber-500"
                >
                  <span className="size-1.5 rounded-full" />
                  {t("pages.provider_collections.partial_payment_badge")}
                </Badge>
              )}
              <StatusBadge status={payment.status} kind="payment" />
            </div>
          </div>
          <div className="flex min-w-0 items-center gap-2">
            <FileText aria-hidden="true" className="size-4 shrink-0" />
            <span className="min-w-0 flex-1 truncate font-medium">
              {payment.receipt_filename}
            </span>
            <Button asChild size="icon-sm" variant="ghost">
              <a
                href={payment.receipt_url ?? undefined}
                download
                aria-label={`Descargar ${payment.receipt_filename ?? "comprobante"}`}
              >
                <Download aria-hidden="true" />
              </a>
            </Button>
          </div>
        </div>
      ))}
    </div>
  )

  if (!showDownloadAll) {
    return list
  }

  function downloadAllReceipts() {
    // Conserva cada comprobante como archivo independiente y con su nombre
    // original al iniciar todas las descargas desde una única acción.
    receipts.forEach((payment) => {
      const link = document.createElement("a")
      link.href = payment.receipt_url ?? ""
      link.download = payment.receipt_filename ?? "comprobante"
      document.body.append(link)
      link.click()
      link.remove()
    })
  }

  return (
    <div className="grid gap-3">
      <Button
        className="h-12 w-full rounded-[10px]"
        type="button"
        onClick={downloadAllReceipts}
      >
        <Download aria-hidden="true" />
        {t("pages.provider_collections.group.download_receipts")}
      </Button>

      {list}
    </div>
  )
}
