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
        receiptUrl="/provider/comprobantes/17/archivo"
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
    expect(screen.getByText("$800")).toBeInTheDocument()
    expect(
      screen.getByText(/importe transferido debe verificarse en el archivo/),
    ).toBeInTheDocument()
    const download = screen.getByRole("link", { name: "Descargar comprobante" })
    expect(download).toHaveAttribute(
      "href",
      "/provider/comprobantes/17/archivo",
    )
    expect(download).toHaveAttribute("download")
  })

  it("prevents current-month approval while allowing rejection", async () => {
    const user = await openReview(false)
    const confirm = screen.getByRole("button", { name: "Aprobar" })
    expect(confirm).toBeDisabled()
    expect(confirm).toHaveAccessibleDescription(/mes en curso/)
    expect(screen.getByRole("button", { name: "Reportar" })).toBeEnabled()
    await user.click(confirm)
    expect(patch).not.toHaveBeenCalled()
  })

  it("approves an eligible payment and prevents duplicate actions during processing", async () => {
    const user = await openReview()
    const confirm = screen.getByRole("button", { name: "Aprobar" })
    expect(confirm).toBeEnabled()
    confirm.focus()
    expect(confirm).toHaveFocus()
    await user.keyboard("{Enter}")
    expect(patch).toHaveBeenCalledWith(
      providerPayments.update(17).url,
      { status: "approved" },
      expect.any(Object),
    )
    expect(screen.getByRole("button", { name: /Aprobando/ })).toBeDisabled()
    expect(screen.getByRole("button", { name: "Reportar" })).toBeDisabled()
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
    ["El pago es parcial", "partial_payment", "partial"],
    ["El comprobante no corresponde", "incorrect_receipt", "rejected"],
  ] as const)(
    "reports with reason %s only after confirmation",
    async (label, reason, result) => {
      const user = await openReview()
      await user.click(screen.getByRole("button", { name: "Reportar" }))
      const dialog = screen.getByRole("dialog", {
        name: "Reportar un problema",
      })
      const submit = within(dialog).getByRole("button", { name: "Continuar" })
      expect(submit).toBeDisabled()

      await user.click(within(dialog).getByRole("radio", { name: label }))
      expect(patch).not.toHaveBeenCalled()
      expect(submit).toBeEnabled()

      await user.click(submit)
      expect(patch).toHaveBeenCalledWith(
        providerPayments.update(17).url,
        {
          status: "rejected",
          rejection_reason: reason,
          rejection_details: null,
        },
        expect.any(Object),
      )
      expect(
        within(dialog).getByRole("button", { name: /Continuando/ }),
      ).toBeDisabled()
      const callbacks = patch.mock.calls[0][2] as {
        onFinish: () => void
        onSuccess: () => void
      }
      act(() => callbacks.onSuccess())
      expect(showResult).toHaveBeenCalledWith(result)
    },
  )

  it("requires and sends a description when reporting with another reason", async () => {
    const user = await openReview()
    await user.click(screen.getByRole("button", { name: "Reportar" }))
    const dialog = screen.getByRole("dialog", {
      name: "Reportar un problema",
    })
    await user.click(within(dialog).getByRole("radio", { name: "Otro motivo" }))

    const details = within(dialog).getByRole("textbox", {
      name: "Describir el motivo",
    })
    const submit = within(dialog).getByRole("button", { name: "Continuar" })
    expect(details).toHaveAttribute("placeholder", "Describir el motivo")
    expect(details).toHaveAttribute("maxlength", "500")
    expect(submit).toBeDisabled()

    await user.type(details, "   ")
    expect(submit).toBeDisabled()

    await user.type(details, "El importe no coincide   ")
    expect(submit).toBeEnabled()
    await user.click(submit)

    expect(patch).toHaveBeenCalledWith(
      providerPayments.update(17).url,
      {
        status: "rejected",
        rejection_reason: "other",
        rejection_details: "El importe no coincide",
      },
      expect.any(Object),
    )
  })

  it("does not show a successful result when reporting does not succeed", async () => {
    const user = await openReview()
    await user.click(screen.getByRole("button", { name: "Reportar" }))
    const dialog = screen.getByRole("dialog", {
      name: "Reportar un problema",
    })
    await user.click(
      within(dialog).getByRole("radio", {
        name: "El comprobante no corresponde",
      }),
    )
    await user.click(within(dialog).getByRole("button", { name: "Continuar" }))

    const callbacks = patch.mock.calls[0][2] as { onFinish: () => void }
    act(() => callbacks.onFinish())

    expect(showResult).not.toHaveBeenCalled()
    expect(
      within(dialog).getByRole("button", { name: "Continuar" }),
    ).toBeEnabled()
  })

  it("returns from rejection without submitting or closing receipt review", async () => {
    const user = await openReview()
    await user.click(screen.getByRole("button", { name: "Reportar" }))
    await user.click(screen.getByRole("radio", { name: "Otro motivo" }))
    await user.type(
      screen.getByRole("textbox", { name: "Describir el motivo" }),
      "Motivo temporal",
    )
    await user.click(screen.getByRole("button", { name: "Volver" }))
    expect(
      screen.getByRole("dialog", { name: "Comprobante" }),
    ).toBeInTheDocument()
    expect(patch).not.toHaveBeenCalled()
    await user.click(screen.getByRole("button", { name: "Reportar" }))
    expect(screen.getByRole("radio", { name: "Otro motivo" })).not.toBeChecked()
    expect(
      screen.queryByRole("textbox", { name: "Describir el motivo" }),
    ).not.toBeInTheDocument()
    expect(screen.getByRole("button", { name: "Continuar" })).toBeDisabled()
  })
})
