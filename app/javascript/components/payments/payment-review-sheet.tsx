import { router } from "@inertiajs/react"
import { Check, X } from "lucide-react"
import type { ReactNode } from "react"
import { useState } from "react"

import ReceiptSheet from "@/components/payments/receipt-sheet"
import RejectPaymentDialog from "@/components/payments/reject-payment-dialog"
import { Button } from "@/components/ui/button"
import { DialogTrigger } from "@/components/ui/dialog"
import { providerPayments } from "@/routes"

interface PaymentReviewSheetProps {
  children: ReactNode
  paymentId: number
  receiptUrl: string
  contentType?: string | null
  filename?: string
}

export default function PaymentReviewSheet({
  children,
  paymentId,
  receiptUrl,
  contentType,
  filename,
}: PaymentReviewSheetProps) {
  const [processing, setProcessing] = useState(false)

  function handleApprove() {
    setProcessing(true)

    router.patch(
      providerPayments.update(paymentId).url,
      { status: "approved" },
      {
        preserveScroll: true,
        onFinish: () => setProcessing(false),
      },
    )
  }

  return (
    <ReceiptSheet
      receiptUrl={receiptUrl}
      contentType={contentType}
      filename={filename}
      footer={
        <>
          <RejectPaymentDialog paymentId={paymentId}>
            <DialogTrigger asChild>
              <Button
                className="flex-1 bg-black text-white hover:bg-black/90"
                size="sm"
              >
                <X className="mr-2 size-4" />
                Rechazar
              </Button>
            </DialogTrigger>
          </RejectPaymentDialog>

          <Button
            variant="outline"
            className="hover:bg-accent hover:text-accent-foreground flex-1 bg-white text-black"
            size="sm"
            disabled={processing}
            onClick={handleApprove}
          >
            <Check className="mr-2 size-4" />
            Aprobar
          </Button>
        </>
      }
    >
      {children}
    </ReceiptSheet>
  )
}
