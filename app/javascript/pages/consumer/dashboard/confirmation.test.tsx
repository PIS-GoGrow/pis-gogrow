import { render, screen } from "@testing-library/react"
import { describe, expect, it, vi } from "vitest"

import OrderConfirmation from "./confirmation"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Link: ({ children, href, ...props }: { children: React.ReactNode; href: string | { url: string } }) => (
      <a href={typeof href === "string" ? href : href.url} {...props}>
        {children}
      </a>
    ),
  }
})

vi.mock("@/layouts/app-layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="app-layout">{children}</div>
  ),
}))

describe("OrderConfirmation Page", () => {
  const sampleOrders = [
    {
      id: 101,
      date: "2026-10-05",
      address: "18 de Julio 1006",
      delivery_method: "office",
      provider_name: "TuViandita",
      name: "Milanesa con puré",
      quantity: 1,
      discounted_price: 150,
    },
    {
      id: 102,
      date: "2026-10-05",
      address: "18 de Julio 1006",
      delivery_method: "office",
      provider_name: "TuViandita",
      name: "Tarta de calabaza",
      quantity: 2,
      discounted_price: 300,
    },
  ]

  it("renders the success header and notification text", () => {
    render(<OrderConfirmation total={450} orders={sampleOrders} />)

    expect(screen.getByText("¡Pedido recibido!")).toBeInTheDocument()
    expect(
      screen.getByText("Te notificaremos cuando el proveedor confirme tu pedido."),
    ).toBeInTheDocument()
  })

  it("displays items grouped by provider with quantities and prices", () => {
    render(<OrderConfirmation total={450} orders={sampleOrders} />)

    expect(screen.getByText("TuViandita")).toBeInTheDocument()
    expect(screen.getByText("Milanesa con puré")).toBeInTheDocument()
    expect(screen.getByText("Tarta de calabaza")).toBeInTheDocument()
    expect(screen.getByText("x1")).toBeInTheDocument()
    expect(screen.getByText("x2")).toBeInTheDocument()
  })

  it("displays the total amount to pay", () => {
    render(<OrderConfirmation total={450} orders={sampleOrders} />)

    expect(screen.getByText("$450")).toBeInTheDocument()
  })

  it("displays delivery address", () => {
    render(<OrderConfirmation total={450} orders={sampleOrders} />)

    expect(screen.getByText(/18 de Julio 1006/)).toBeInTheDocument()
  })

  it("contains a link to view consumer orders", () => {
    render(<OrderConfirmation total={450} orders={sampleOrders} />)

    const ordersLink = screen.getByRole("link", { name: "Ver mis pedidos" })
    expect(ordersLink).toBeInTheDocument()
    expect(ordersLink).toHaveAttribute("href", "/orders")
  })
})
