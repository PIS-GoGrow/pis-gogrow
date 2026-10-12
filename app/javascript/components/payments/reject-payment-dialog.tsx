import { router } from "@inertiajs/react"
import type { ReactNode } from "react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import {
  AdaptableDialog,
  AdaptableDialogContent,
  AdaptableDialogDescription,
  AdaptableDialogFooter,
  AdaptableDialogHeader,
  AdaptableDialogTitle,
} from "@/components/adaptable-dialog"
import { Button } from "@/components/ui/button"
import { Field, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { PARTIAL_PAYMENT_REJECTION_REASON } from "@/lib/payment-rejection-reasons"
import { cn } from "@/lib/utils"
import { providerPayments as paymentsRoutes } from "@/routes"

const REJECTION_REASONS = [
  "La imagen está borrosa",
  "El archivo enviado no corresponde a un comprobante",
  PARTIAL_PAYMENT_REJECTION_REASON,
]

const OTHER_OPTION = "other"

interface RejectPaymentDialogProps {
  children: ReactNode
  paymentId: number
  onRejected?: (reason: string) => void
}

export default function RejectPaymentDialog({
  children,
  paymentId,
  onRejected,
}: RejectPaymentDialogProps) {
  const { t } = useTranslation()
  const page = "pages.provider_collections.review"
  const [open, setOpen] = useState(false)
  const [selectedReason, setSelectedReason] = useState<string>(
    REJECTION_REASONS[0],
  )
  const [customReason, setCustomReason] = useState("")
  const [processing, setProcessing] = useState(false)

  const isOther = selectedReason === OTHER_OPTION
  const finalReason = isOther ? customReason.trim() : selectedReason
  const canSubmit = finalReason.length > 0

  function resetForm() {
    setSelectedReason(REJECTION_REASONS[0])
    setCustomReason("")
  }

  function handleReject() {
    if (!canSubmit || processing) return

    setProcessing(true)

    router.patch(
      paymentsRoutes.update(paymentId).url,
      { status: "rejected", rejection_reason: finalReason },
      {
        preserveState: true,
        onSuccess: () => {
          setOpen(false)
          resetForm()
          onRejected?.(finalReason)
        },
        onFinish: () => setProcessing(false),
      },
    )
  }

  return (
    <AdaptableDialog
      open={open}
      onOpenChange={(nextOpen) => {
        setOpen(nextOpen)
        if (!nextOpen) resetForm()
      }}
    >
      {children}

      <AdaptableDialogContent>
        <AdaptableDialogHeader>
          <AdaptableDialogTitle>
            {t(`${page}.issue_title`)}
          </AdaptableDialogTitle>
          <AdaptableDialogDescription>
            {t(`${page}.issue_description`)}
          </AdaptableDialogDescription>
        </AdaptableDialogHeader>

        <div className="flex flex-col gap-2 px-4 sm:px-0">
          {REJECTION_REASONS.map((reason) => (
            <label
              key={reason}
              className={cn(
                "flex cursor-pointer items-center gap-3 rounded-xl border p-3 text-sm transition-colors",
                selectedReason === reason
                  ? "border-primary bg-primary/5"
                  : "hover:border-primary/50",
              )}
            >
              <input
                type="radio"
                name="rejection_reason"
                className="accent-primary"
                checked={selectedReason === reason}
                onChange={() => setSelectedReason(reason)}
              />
              {reason}
            </label>
          ))}

          <label
            className={cn(
              "flex cursor-pointer items-center gap-3 rounded-xl border p-3 text-sm transition-colors",
              isOther
                ? "border-primary bg-primary/5"
                : "hover:border-primary/50",
            )}
          >
            <input
              type="radio"
              name="rejection_reason"
              className="accent-primary"
              checked={isOther}
              onChange={() => setSelectedReason(OTHER_OPTION)}
            />
            Otro
          </label>

          {isOther && (
            <Field>
              <FieldLabel htmlFor="custom-reason" className="sr-only">
                Motivo
              </FieldLabel>
              <Input
                id="custom-reason"
                placeholder="Escribí el motivo..."
                value={customReason}
                onChange={(e) => setCustomReason(e.target.value)}
              />
            </Field>
          )}
        </div>

        <AdaptableDialogFooter className="flex-row gap-3 px-4 pb-4 sm:justify-start sm:p-0">
          <Button
            variant="secondary"
            className="h-12 min-w-0 flex-1 whitespace-normal"
            disabled={processing}
            onClick={() => {
              setOpen(false)
              resetForm()
            }}
          >
            {t(`${page}.back`)}
          </Button>
          <Button
            className="h-12 min-w-0 flex-1 whitespace-normal"
            size="sm"
            disabled={!canSubmit || processing}
            aria-busy={processing}
            onClick={handleReject}
          >
            {t(`${page}.${processing ? "rejecting" : "reject_receipt"}`)}
          </Button>
        </AdaptableDialogFooter>
      </AdaptableDialogContent>
    </AdaptableDialog>
  )
}
