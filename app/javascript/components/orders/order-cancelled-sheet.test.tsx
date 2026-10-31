import { usePage } from "@inertiajs/react"
import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { beforeEach, describe, expect, it, vi } from "vitest"

import OrderCancelledSheet from "./order-cancelled-sheet"

vi.mock("@inertiajs/react", () => ({ usePage: vi.fn() }))

vi.mock("@/hooks/use-mobile", () => ({ useIsMobile: () => true }))

const mockFlash = (flash: Record<string, unknown>) =>
  vi.mocked(usePage).mockReturnValue({
    flash,
  } as unknown as ReturnType<typeof usePage>)

describe("OrderCancelledSheet", () => {
  beforeEach(() => vi.clearAllMocks())

  it("shows the confirmation when the order was cancelled", async () => {
    mockFlash({ order_cancelled: true })

    render(<OrderCancelledSheet />)

    expect(
      await screen.findByRole("dialog", { name: "Pedido cancelado" }),
    ).toBeInTheDocument()
    expect(
      screen.getByText("Podés hacer un nuevo pedido cuando quieras."),
    ).toBeInTheDocument()
  })

  it("closes when pressing Listo", async () => {
    mockFlash({ order_cancelled: true })

    render(<OrderCancelledSheet />)
    await userEvent.click(await screen.findByRole("button", { name: "Listo" }))

    expect(screen.queryByRole("dialog")).not.toBeInTheDocument()
  })

  it("stays closed without the cancellation flash", () => {
    mockFlash({})

    render(<OrderCancelledSheet />)

    expect(screen.queryByRole("dialog")).not.toBeInTheDocument()
  })
})
