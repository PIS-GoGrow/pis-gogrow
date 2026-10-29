import { usePage } from "@inertiajs/react"
import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { beforeEach, describe, expect, it, vi } from "vitest"

import OrderUpdatedSheet from "./order-updated-sheet"

const visit = vi.hoisted(() => vi.fn())

vi.mock("@inertiajs/react", () => ({
  usePage: vi.fn(),
  router: { visit },
}))

vi.mock("@/hooks/use-mobile", () => ({ useIsMobile: () => true }))

const mockFlash = (flash: Record<string, unknown>) =>
  vi.mocked(usePage).mockReturnValue({ flash } as ReturnType<typeof usePage>)

describe("OrderUpdatedSheet", () => {
  beforeEach(() => vi.clearAllMocks())

  it("shows the confirmation when the order was modified", async () => {
    mockFlash({ order_updated: true })

    render(<OrderUpdatedSheet />)

    expect(
      await screen.findByRole("dialog", { name: "Pedido modificado" }),
    ).toBeInTheDocument()
    expect(
      screen.getByText(
        "Te notificaremos cuando el proveedor confirme tu pedido.",
      ),
    ).toBeInTheDocument()
  })

  it("goes back to Mis pedidos when pressing Listo", async () => {
    mockFlash({ order_updated: true })

    render(<OrderUpdatedSheet />)
    await userEvent.click(await screen.findByRole("button", { name: "Listo" }))

    expect(visit).toHaveBeenCalledWith("/pedidos")
    expect(screen.queryByRole("dialog")).not.toBeInTheDocument()
  })

  it("stays closed without the modification flash", () => {
    mockFlash({})

    render(<OrderUpdatedSheet />)

    expect(screen.queryByRole("dialog")).not.toBeInTheDocument()
  })
})
