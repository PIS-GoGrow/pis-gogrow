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
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import {
  PAYMENT_REJECTION_REASON_KEYS,
  type PaymentRejectionReasonKey,
} from "@/lib/payment-rejection-reasons"
import { cn } from "@/lib/utils"
import { providerPayments as paymentsRoutes } from "@/routes"

interface RejectPaymentDialogProps {
  children: ReactNode
  paymentId: number
  onRejected?: (reason: PaymentRejectionReasonKey) => void
}

export default function RejectPaymentDialog({
  children,
  paymentId,
  onRejected,
}: RejectPaymentDialogProps) {
  const { t } = useTranslation()
  const page = "pages.provider_collections.review"
  const [open, setOpen] = useState(false)
  const [selectedReason, setSelectedReason] =
    useState<PaymentRejectionReasonKey | null>(null)
  const [rejectionDetails, setRejectionDetails] = useState("")
  const [processing, setProcessing] = useState(false)

  const isOtherReason = selectedReason === "other"
  const normalizedDetails = rejectionDetails.trim()
  const canSubmit =
    selectedReason !== null && (!isOtherReason || normalizedDetails.length > 0)

  function resetForm() {
    setSelectedReason(null)
    setRejectionDetails("")
  }

  function handleConfirm() {
    if (!selectedReason || !canSubmit || processing) return

    setProcessing(true)

    router.patch(
      paymentsRoutes.update(paymentId).url,
      {
        status: "rejected",
        rejection_reason: selectedReason,
        rejection_details: isOtherReason ? normalizedDetails : null,
      },
      {
        preserveState: true,
        onSuccess: () => {
          setOpen(false)
          resetForm()
          onRejected?.(selectedReason)
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

        <RadioGroup
          value={selectedReason ?? ""}
          onValueChange={(reason) =>
            setSelectedReason(reason as PaymentRejectionReasonKey)
          }
          className="gap-2 px-4 sm:px-0"
        >
          {PAYMENT_REJECTION_REASON_KEYS.map((reason) => {
            const id = `payment-rejection-${reason}`

            return (
              <FieldLabel key={reason} htmlFor={id}>
                <Field
                  orientation="horizontal"
                  className={cn(
                    "cursor-pointer rounded-lg border p-3 transition-colors",
                    selectedReason === reason
                      ? "border-primary bg-primary/5"
                      : "hover:border-primary/50",
                  )}
                >
                  <RadioGroupItem id={id} value={reason} />
                  <span className="font-normal">
                    {t(`${page}.reasons.${reason}`)}
                  </span>
                </Field>
              </FieldLabel>
            )
          })}
        </RadioGroup>

        {isOtherReason && (
          <Field className="px-4 sm:px-0">
            <FieldLabel htmlFor="payment-rejection-details" className="sr-only">
              {t(`${page}.details_label`)}
            </FieldLabel>
            <Input
              id="payment-rejection-details"
              value={rejectionDetails}
              onChange={(event) => setRejectionDetails(event.target.value)}
              placeholder={t(`${page}.details_placeholder`)}
              maxLength={500}
              disabled={processing}
            />
          </Field>
        )}

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
            onClick={handleConfirm}
          >
            {t(`${page}.${processing ? "continuing" : "continue"}`)}
          </Button>
        </AdaptableDialogFooter>
      </AdaptableDialogContent>
    </AdaptableDialog>
  )
}
