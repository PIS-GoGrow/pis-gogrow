import type { PaymentStatus } from "@/types"

export const PAYMENT_REJECTION_REASON_KEYS = [
  "incorrect_receipt",
  "other",
] as const

export type PaymentRejectionReasonKey =
  (typeof PAYMENT_REJECTION_REASON_KEYS)[number]

export const PARTIAL_PAYMENT_REJECTION_REASON_KEY = "partial_payment"

export const PAYMENT_REVIEW_ISSUE_KEYS = [
  PARTIAL_PAYMENT_REJECTION_REASON_KEY,
  ...PAYMENT_REJECTION_REASON_KEYS,
] as const

export type PaymentReviewIssueKey = (typeof PAYMENT_REVIEW_ISSUE_KEYS)[number]

// Los pagos existentes guardan el texto visible, por eso esta comparación se
// mantiene separada de las claves estables que usa el formulario de revisión.
export const PARTIAL_PAYMENT_REJECTION_REASON = "El pago es parcial"
interface PaymentStatusPresentation {
  status: PaymentStatus
  rejection_reason: string | null
}

export function paymentPresentationStatus({
  status,
  rejection_reason: rejectionReason,
}: PaymentStatusPresentation): PaymentStatus {
  if (
    status === "rejected" &&
    rejectionReason === PARTIAL_PAYMENT_REJECTION_REASON
  ) {
    return "partial"
  }

  return status
}
