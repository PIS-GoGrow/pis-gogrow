import { createContext, useContext } from "react"

// "approved" | "partial" | "rejected": el mismo pago puede rechazarse por
// motivo "pago parcial" o por cualquier otro, y cada uno tiene su propio
// mensaje (ver PaymentReviewResultDialog).
export type PaymentReviewResult = "approved" | "partial" | "rejected"

// Mostrar el resultado de una revisión vive en el Provider en vez de en
// PaymentReviewSheet: al aprobar o rechazar el último comprobante pendiente
// de una cuenta, esa cuenta (o todo su grupo) puede desaparecer de la pestaña
// actual en el mismo render, lo que desmontaría PaymentReviewSheet antes de
// que el mensaje llegue a verse. El contexto lo desacopla de esa fila.
const PaymentReviewResultContext = createContext<
  ((result: PaymentReviewResult) => void) | null
>(null)

export const PaymentReviewResultProvider = PaymentReviewResultContext.Provider

export function usePaymentReviewResult() {
  const showResult = useContext(PaymentReviewResultContext)

  if (!showResult) {
    throw new Error(
      "usePaymentReviewResult debe usarse dentro de <PaymentReviewResultProvider>",
    )
  }

  return showResult
}
