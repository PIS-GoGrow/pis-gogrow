import { render, screen } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import { PARTIAL_PAYMENT_REJECTION_REASON } from "@/lib/payment-rejection-reasons"

import RejectionNotice from "./rejection-notice"

describe("RejectionNotice", () => {
  it("renders amber alert when reason is partial payment", () => {
    render(
      <RejectionNotice
        reason={PARTIAL_PAYMENT_REJECTION_REASON}
        partialPaymentWarning="Falta una parte del pago."
        rejectedLabel="Rechazado"
      />,
    )

    expect(screen.getByText("Falta una parte del pago.")).toBeInTheDocument()
    expect(screen.queryByText("Rechazado:")).not.toBeInTheDocument()
  })

  it("renders red box with rejection reason when reason is another text", () => {
    render(
      <RejectionNotice
        reason="Comprobante ilegible o cortado"
        partialPaymentWarning="Falta una parte del pago."
        rejectedLabel="Rechazado"
      />,
    )

    expect(screen.getByText("Rechazado:")).toBeInTheDocument()
    expect(
      screen.getByText(/Comprobante ilegible o cortado/),
    ).toBeInTheDocument()
    expect(
      screen.queryByText("Falta una parte del pago."),
    ).not.toBeInTheDocument()
  })
})
