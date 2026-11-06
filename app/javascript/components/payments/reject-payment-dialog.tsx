import { router } from "@inertiajs/react"
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
  PARTIAL_PAYMENT_REJECTION_REASON_KEY,
  PAYMENT_REVIEW_ISSUE_KEYS,
  type PaymentReviewIssueKey,
} from "@/lib/payment-rejection-reasons"
import { providerPayments as paymentsRoutes } from "@/routes"

interface RejectPaymentDialogProps {
  paymentId: number
  open: boolean
  onOpenChange: (open: boolean) => void
  onReviewed?: (result: "partial" | "rejected") => void
}

export default function RejectPaymentDialog({
  paymentId,
  open,
  onOpenChange,
  onReviewed,
}: RejectPaymentDialogProps) {
  const { t } = useTranslation()
  const page = "pages.provider_collections.review"
  const [selectedReason, setSelectedReason] =
    useState<PaymentReviewIssueKey | null>(null)
  const [rejectionDetails, setRejectionDetails] = useState("")
  const [processing, setProcessing] = useState(false)

  const isOtherReason = selectedReason === "other"
  const isPartialPayment =
    selectedReason === PARTIAL_PAYMENT_REJECTION_REASON_KEY
  const normalizedDetails = rejectionDetails.trim()
  const canSubmit = selectedReason !== null

  function resetForm() {
    setSelectedReason(null)
    setRejectionDetails("")
  }

  function handleConfirm() {
    if (!selectedReason || !canSubmit || processing) return

    setProcessing(true)

    const payload = isPartialPayment
      ? { status: "partial" }
      : {
          status: "rejected",
          rejection_reason: selectedReason,
          rejection_details: isOtherReason ? normalizedDetails || null : null,
        }

    router.patch(paymentsRoutes.update(paymentId).url, payload, {
      preserveState: true,
      onSuccess: () => {
        resetForm()
        onReviewed?.(isPartialPayment ? "partial" : "rejected")
      },
      onFinish: () => setProcessing(false),
    })
  }

  return (
    <AdaptableDialog
      open={open}
      onOpenChange={(nextOpen) => {
        onOpenChange(nextOpen)
        if (!nextOpen) resetForm()
      }}
    >
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
            setSelectedReason(reason as PaymentReviewIssueKey)
          }
          required
          className="gap-2 px-4 sm:px-0"
        >
          {PAYMENT_REVIEW_ISSUE_KEYS.map((reason) => {
            const id = `payment-rejection-${reason}`

            return (
              <FieldLabel
                key={reason}
                htmlFor={id}
                className="hover:border-primary/50 has-data-[state=checked]:border-border has-data-[state=checked]:bg-transparent dark:has-data-[state=checked]:bg-transparent"
              >
                <Field
                  orientation="horizontal"
                  className="cursor-pointer transition-colors"
                >
                  <RadioGroupItem
                    id={id}
                    value={reason}
                    data-testid={`provider-payment-report-reason-${reason}`}
                  />
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
              onOpenChange(false)
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
