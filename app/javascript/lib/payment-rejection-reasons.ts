import type { PaymentStatus } from "@/types"

export const PAYMENT_REJECTION_REASON_KEYS = [
  "partial_payment",
  "incorrect_receipt",
  "other",
] as const

export type PaymentRejectionReasonKey =
  (typeof PAYMENT_REJECTION_REASON_KEYS)[number]

export const PARTIAL_PAYMENT_REJECTION_REASON_KEY = "partial_payment"

// Los pagos existentes guardan el texto visible, por eso esta comparación se
// mantiene separada de las claves estables que usa el formulario de revisión.
export const PARTIAL_PAYMENT_REJECTION_REASON = "El pago es parcial"

// El motivo del último rechazo sigue vigente aunque después haya otro
// comprobante en revisión; deja de importar recién cuando se aprueba un pago.
export function pendingRejectionReason(
  paymentsNewestFirst: {
    status: PaymentStatus
    rejection_reason: string | null
  }[],
) {
  if (paymentsNewestFirst.some(({ status }) => status === "approved")) {
    return null
  }

  return (
    paymentsNewestFirst.find(({ status }) => status === "rejected")
      ?.rejection_reason ?? null
  )
}
