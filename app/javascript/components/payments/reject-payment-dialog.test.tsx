import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { beforeEach, describe, expect, it, vi } from "vitest"

import { providerPayments } from "@/routes"

import RejectPaymentDialog from "./reject-payment-dialog"

const { patch } = vi.hoisted(() => ({ patch: vi.fn() }))

vi.mock("@inertiajs/react", async () => ({
  ...(await vi.importActual("@inertiajs/react")),
  router: { patch },
  usePage: () => ({ props: { locale: "es" } }),
}))

function renderDialog() {
  render(
    <RejectPaymentDialog paymentId={17} open onOpenChange={() => undefined} />,
  )
  return userEvent.setup()
}

const url = providerPayments.update(17).url

beforeEach(() => vi.clearAllMocks())

describe("RejectPaymentDialog", () => {
  it("requires a reason before continuing", async () => {
    const user = renderDialog()
    const submit = screen.getByRole("button", { name: "Continuar" })
    expect(submit).toBeDisabled()
    await user.click(submit)
    expect(patch).not.toHaveBeenCalled()
  })

  it("sends an 'Otro motivo' report without a description", async () => {
    const user = renderDialog()
    await user.click(screen.getByRole("radio", { name: "Otro motivo" }))
    expect(
      screen.getByRole("textbox", { name: "Describir el motivo" }),
    ).toHaveValue("")
    await user.click(screen.getByRole("button", { name: "Continuar" }))
    expect(patch).toHaveBeenCalledWith(
      url,
      {
        status: "rejected",
        rejection_reason: "other",
        rejection_details: null,
      },
      expect.anything(),
    )
  })

  it("sends the trimmed description for 'Otro motivo'", async () => {
    const user = renderDialog()
    await user.click(screen.getByRole("radio", { name: "Otro motivo" }))
    await user.type(
      screen.getByRole("textbox", { name: "Describir el motivo" }),
      "  Falta el concepto  ",
    )
    await user.click(screen.getByRole("button", { name: "Continuar" }))
    expect(patch).toHaveBeenCalledWith(
      url,
      expect.objectContaining({ rejection_details: "Falta el concepto" }),
      expect.anything(),
    )
  })

  it("does not send the description for a fixed reason", async () => {
    const user = renderDialog()
    await user.click(
      screen.getByRole("radio", { name: "El comprobante no corresponde" }),
    )
    expect(screen.queryByRole("textbox")).not.toBeInTheDocument()
    await user.click(screen.getByRole("button", { name: "Continuar" }))
    expect(patch).toHaveBeenCalledWith(
      url,
      {
        status: "rejected",
        rejection_reason: "incorrect_receipt",
        rejection_details: null,
      },
      expect.anything(),
    )
  })

  it("marks a partial payment with the partial status", async () => {
    const user = renderDialog()
    await user.click(screen.getByRole("radio", { name: "El pago es parcial" }))
    await user.click(screen.getByRole("button", { name: "Continuar" }))
    expect(patch).toHaveBeenCalledWith(
      url,
      { status: "partial" },
      expect.anything(),
    )
  })
})
