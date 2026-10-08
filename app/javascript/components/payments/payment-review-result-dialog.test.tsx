import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it, vi } from "vitest"

import PaymentReviewResultDialog from "./payment-review-result-dialog"

describe("PaymentReviewResultDialog", () => {
  it("renders nothing when result is null", () => {
    const { container } = render(
      <PaymentReviewResultDialog result={null} onClose={vi.fn()} />,
    )

    expect(container).toBeEmptyDOMElement()
  })

  it("renders approved title and description when result is approved", () => {
    render(<PaymentReviewResultDialog result="approved" onClose={vi.fn()} />)

    expect(screen.getByText("Cobro confirmado")).toBeInTheDocument()
    expect(
      screen.getByText(
        "El cobro fue confirmado correctamente. Se notificará al usuario.",
      ),
    ).toBeInTheDocument()
  })

  it("renders partial payment title and description when result is partial", () => {
    render(<PaymentReviewResultDialog result="partial" onClose={vi.fn()} />)

    expect(screen.getByText("Pago parcial registrado")).toBeInTheDocument()
    expect(
      screen.getByText(
        "El comprobante quedó registrado como pago parcial. Se notificará al usuario para que abone el monto restante.",
      ),
    ).toBeInTheDocument()
  })

  it("renders generic rejection title and description when result is rejected", () => {
    render(<PaymentReviewResultDialog result="rejected" onClose={vi.fn()} />)

    expect(screen.getByText("Comprobante rechazado")).toBeInTheDocument()
    expect(
      screen.getByText(
        "El comprobante fue rechazado. El cobro continúa pendiente y se notificará al usuario.",
      ),
    ).toBeInTheDocument()
  })

  it("calls onClose when the done button is clicked", async () => {
    const user = userEvent.setup()
    const handleClose = vi.fn()

    render(
      <PaymentReviewResultDialog result="approved" onClose={handleClose} />,
    )

    await user.click(screen.getByRole("button", { name: "Listo" }))

    expect(handleClose).toHaveBeenCalledOnce()
  })
})
