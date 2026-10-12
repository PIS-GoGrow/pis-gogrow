import { act, render, screen, within } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { beforeEach, describe, expect, it, vi } from "vitest"

import { AdaptableDialogTrigger } from "@/components/adaptable-dialog"
import { Button } from "@/components/ui/button"
import { providerPayments } from "@/routes"

import { PaymentReviewResultProvider } from "./payment-review-result-context"
import PaymentReviewSheet from "./payment-review-sheet"

const { patch, showResult } = vi.hoisted(() => ({
  patch: vi.fn(),
  showResult: vi.fn(),
}))

vi.mock("@inertiajs/react", async () => ({
  ...(await vi.importActual("@inertiajs/react")),
  router: { patch },
  usePage: () => ({ props: { locale: "es" } }),
}))

async function openReview(canApprove = true) {
  render(
    <PaymentReviewResultProvider value={showResult}>
      <PaymentReviewSheet
        paymentId={17}
        receiptUrl="/provider/payments/17/receipt"
        contentType="image/png"
        filename="Empleado de prueba"
        expectedAmount={800}
        canApprove={canApprove}
      >
        <AdaptableDialogTrigger asChild>
          <Button>Revisar pago</Button>
        </AdaptableDialogTrigger>
      </PaymentReviewSheet>
    </PaymentReviewResultProvider>,
  )
  const user = userEvent.setup()
  await user.click(screen.getByRole("button", { name: "Revisar pago" }))
  return user
}

beforeEach(() => vi.clearAllMocks())

describe("PaymentReviewSheet", () => {
  it("shows the account amount and downloads the existing protected receipt", async () => {
    await openReview()
    expect(screen.getByText("Importe esperado:")).toBeInTheDocument()
    expect(screen.getByText("800,00 UYU")).toBeInTheDocument()
    expect(
      screen.getByText(/importe transferido debe verificarse en el archivo/),
    ).toBeInTheDocument()
    const download = screen.getByRole("link", { name: "Descargar comprobante" })
    expect(download).toHaveAttribute("href", "/provider/payments/17/receipt")
    expect(download).toHaveAttribute("download")
  })

  it("prevents current-month approval while allowing rejection", async () => {
    const user = await openReview(false)
    const approve = screen.getByRole("button", { name: "Aprobar" })
    expect(approve).toBeDisabled()
    expect(approve).toHaveAccessibleDescription(/mes en curso/)
    expect(screen.getByRole("button", { name: "Rechazar" })).toBeEnabled()
    await user.click(approve)
    expect(patch).not.toHaveBeenCalled()
  })

  it("approves an eligible payment and prevents duplicate actions during processing", async () => {
    const user = await openReview()
    const approve = screen.getByRole("button", { name: "Aprobar" })
    expect(approve).toBeEnabled()
    approve.focus()
    expect(approve).toHaveFocus()
    await user.keyboard("{Enter}")
    expect(patch).toHaveBeenCalledWith(
      providerPayments.update(17).url,
      { status: "approved" },
      expect.any(Object),
    )
    expect(screen.getByRole("button", { name: /Aprobando/ })).toBeDisabled()
    expect(screen.getByRole("button", { name: "Rechazar" })).toBeDisabled()
    const callbacks = patch.mock.calls[0][2] as {
      onFinish: () => void
      onSuccess: () => void
    }
    act(() => callbacks.onFinish())
    expect(screen.getByRole("button", { name: "Aprobar" })).toBeEnabled()
    act(() => callbacks.onSuccess())
    expect(showResult).toHaveBeenCalledWith("approved")
  })

  it.each([
    "La imagen está borrosa",
    "El archivo enviado no corresponde a un comprobante",
    "El pago es parcial",
    "Otro",
  ])("preserves rejection with reason %s", async (reason) => {
    const user = await openReview()
    await user.click(screen.getByRole("button", { name: "Rechazar" }))
    const dialog = screen.getByRole("dialog", { name: "Reportar un problema" })
    await user.click(within(dialog).getByRole("radio", { name: reason }))
    const submit = within(dialog).getByRole("button", {
      name: "Rechazar comprobante",
    })
    if (reason === "Otro") {
      expect(submit).toBeDisabled()
      await user.type(
        within(dialog).getByRole("textbox", { name: "Motivo" }),
        "  Motivo de prueba  ",
      )
    }
    await user.click(submit)
    expect(patch).toHaveBeenCalledWith(
      providerPayments.update(17).url,
      {
        status: "rejected",
        rejection_reason: reason === "Otro" ? "Motivo de prueba" : reason,
      },
      expect.any(Object),
    )
    expect(
      within(dialog).getByRole("button", { name: /Rechazando/ }),
    ).toBeDisabled()
    const callbacks = patch.mock.calls[0][2] as {
      onFinish: () => void
      onSuccess: () => void
    }
    act(() => callbacks.onSuccess())
    expect(showResult).toHaveBeenCalledWith(
      reason === "El pago es parcial" ? "partial" : "rejected",
    )
  })

  it("returns from rejection without submitting or closing receipt review", async () => {
    const user = await openReview()
    await user.click(screen.getByRole("button", { name: "Rechazar" }))
    await user.click(screen.getByRole("radio", { name: "Otro" }))
    await user.type(screen.getByRole("textbox", { name: "Motivo" }), "Prueba")
    await user.click(screen.getByRole("button", { name: "Volver" }))
    expect(
      screen.getByRole("dialog", { name: "Comprobante" }),
    ).toBeInTheDocument()
    expect(patch).not.toHaveBeenCalled()
    await user.click(screen.getByRole("button", { name: "Rechazar" }))
    expect(
      screen.getByRole("radio", { name: "La imagen está borrosa" }),
    ).toBeChecked()
    expect(
      screen.queryByRole("textbox", { name: "Motivo" }),
    ).not.toBeInTheDocument()
  })
})
