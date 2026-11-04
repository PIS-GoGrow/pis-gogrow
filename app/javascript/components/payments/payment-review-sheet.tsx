import { router } from "@inertiajs/react"
import { Check, X } from "lucide-react"
import type { ReactNode } from "react"
import { useId, useState } from "react"
import { useTranslation } from "react-i18next"

import { AdaptableDialogTrigger } from "@/components/adaptable-dialog"
import { usePaymentReviewResult } from "@/components/payments/payment-review-result-context"
import ReceiptSheet from "@/components/payments/receipt-sheet"
import RejectPaymentDialog from "@/components/payments/reject-payment-dialog"
import { Button } from "@/components/ui/button"
import { Spinner } from "@/components/ui/spinner"
import { providerPayments } from "@/routes"

interface PaymentReviewSheetProps {
  children: ReactNode
  paymentId: number
  receiptUrl: string
  contentType?: string | null
  filename?: string
  expectedAmount: number
  canApprove: boolean
}

export default function PaymentReviewSheet({
  children,
  paymentId,
  receiptUrl,
  contentType,
  filename,
  expectedAmount,
  canApprove,
}: PaymentReviewSheetProps) {
  const { t } = useTranslation()
  const restrictionId = useId()
  const showResult = usePaymentReviewResult()
  const [processing, setProcessing] = useState(false)
  const [sheetOpen, setSheetOpen] = useState(false)

  function handleConfirm() {
    if (!canApprove || processing) return
    setProcessing(true)

    router.patch(
      providerPayments.update(paymentId).url,
      { status: "approved" },
      {
        preserveScroll: true,
        preserveState: true,
        onSuccess: () => {
          setSheetOpen(false)
          showResult("approved")
        },
        onFinish: () => setProcessing(false),
      },
    )
  }

  function handleReviewed(result: "partial" | "rejected") {
    setSheetOpen(false)
    showResult(result)
  }

  return (
    <ReceiptSheet
      receiptUrl={receiptUrl}
      contentType={contentType}
      filename={filename}
      expectedAmount={expectedAmount}
      notice={
        !canApprove && (
          <p id={restrictionId} className="text-muted-foreground text-sm">
            {t("pages.provider_collections.review.current_month_restriction")}
          </p>
        )
      }
      open={sheetOpen}
      onOpenChange={setSheetOpen}
      footer={
        <>
          <RejectPaymentDialog
            paymentId={paymentId}
            onReviewed={handleReviewed}
          >
            <AdaptableDialogTrigger asChild>
              <Button
                variant="secondary"
                className="h-12 flex-1"
                size="sm"
                disabled={processing}
              >
                <X className="mr-2 size-4" />
                {t("pages.provider_collections.review.report")}
              </Button>
            </AdaptableDialogTrigger>
          </RejectPaymentDialog>

          <Button
            className="h-12 flex-1"
            size="sm"
            disabled={processing || !canApprove}
            aria-describedby={!canApprove ? restrictionId : undefined}
            aria-busy={processing}
            onClick={handleConfirm}
          >
            {processing ? (
              <Spinner
                aria-label={t("pages.provider_collections.review.confirming")}
              />
            ) : (
              <Check aria-hidden="true" />
            )}
            {t(
              `pages.provider_collections.review.${processing ? "confirming" : "confirm"}`,
            )}
          </Button>
        </>
      }
    >
      {children}
    </ReceiptSheet>
  )
}
