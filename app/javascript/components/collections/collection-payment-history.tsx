import { Download, FileText } from "lucide-react"
import { useTranslation } from "react-i18next"

import StatusBadge from "@/components/status-badge"
import { Button } from "@/components/ui/button"
import { paymentPresentationStatus } from "@/lib/payment-rejection-reasons"
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

  // En el historial, un solo comprobante se baja con un botón; mientras el cobro
  // sigue abierto se muestra la tarjeta, que lleva el estado y no compite con
  // la acción principal de la cuenta.
  if (receipts.length === 1 && showDownloadAll) {
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
    <div className="grid min-w-0 grid-cols-1 gap-2">
      {receipts.map((payment) => (
        <div
          key={payment.id}
          className="bg-background grid min-w-0 grid-cols-1 gap-3 rounded-lg border p-3 text-sm"
        >
          <div className="flex items-start justify-between gap-2">
            <span className="text-muted-foreground leading-6">
              {payment.date}
            </span>
            <StatusBadge
              status={paymentPresentationStatus(payment)}
              kind="provider_payment"
            />
          </div>
          <div className="flex min-w-0 items-center gap-3">
            <span className="bg-muted flex size-10 shrink-0 items-center justify-center rounded-md">
              <FileText aria-hidden="true" className="size-5" />
            </span>
            <span className="grid min-w-0 flex-1">
              <span className="truncate font-medium">
                {payment.receipt_filename}
              </span>
              <span className="text-muted-foreground text-xs">
                {payment.receipt_size}
              </span>
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
    <div className="grid min-w-0 grid-cols-1 gap-3">
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
