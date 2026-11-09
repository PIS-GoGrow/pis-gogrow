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
