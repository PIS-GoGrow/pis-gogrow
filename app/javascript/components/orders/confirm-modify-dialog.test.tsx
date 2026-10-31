import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it, vi } from "vitest"

import ConfirmModifyDialog from "./confirm-modify-dialog"

vi.mock("@/hooks/use-mobile", () => ({ useIsMobile: () => true }))

describe("ConfirmModifyDialog", () => {
  it("asks to modify a confirmed order and confirms", async () => {
    const onConfirm = vi.fn()

    render(
      <ConfirmModifyDialog
        kind="modify_confirmed"
        processing={false}
        onConfirm={onConfirm}
        onClose={vi.fn()}
      />,
    )

    expect(
      await screen.findByRole("dialog", { name: "¿Modificar el pedido?" }),
    ).toBeInTheDocument()

    await userEvent.click(
      screen.getByRole("button", { name: "Modificar pedido" }),
    )

    expect(onConfirm).toHaveBeenCalled()
  })

  it("explains that adding units sends a complementary order", async () => {
    render(
      <ConfirmModifyDialog
        kind="add_units"
        processing={false}
        onConfirm={vi.fn()}
        onClose={vi.fn()}
      />,
    )

    expect(
      await screen.findByRole("dialog", { name: "¿Agregar más unidades?" }),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("button", { name: "Aumentar pedido" }),
    ).toBeInTheDocument()
  })

  it("closes when going back", async () => {
    const onClose = vi.fn()

    render(
      <ConfirmModifyDialog
        kind="modify_confirmed"
        processing={false}
        onConfirm={vi.fn()}
        onClose={onClose}
      />,
    )

    await userEvent.click(await screen.findByRole("button", { name: "Volver" }))

    expect(onClose).toHaveBeenCalled()
  })

  it("stays closed without a kind", () => {
    render(
      <ConfirmModifyDialog
        kind={null}
        processing={false}
        onConfirm={vi.fn()}
        onClose={vi.fn()}
      />,
    )

    expect(screen.queryByRole("dialog")).not.toBeInTheDocument()
  })
})
