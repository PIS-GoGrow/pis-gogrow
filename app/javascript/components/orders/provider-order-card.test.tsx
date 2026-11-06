import { render, screen } from "@testing-library/react"
import type React from "react"
import { describe, expect, it, vi } from "vitest"

import type { ProviderOrder } from "@/types"

import ProviderOrderCard from "./provider-order-card"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    router: { patch: vi.fn() },
    Link: ({
      children,
      href,
      className,
    }: {
      children: React.ReactNode
      href: string
      className?: string
    }) => (
      <a href={href} className={className}>
        {children}
      </a>
    ),
  }
})

function order(overrides: Partial<ProviderOrder>): ProviderOrder {
  return {
    id: 1,
    status: "pending",
    amount: 1,
    notes: null,
    delivery_method: "office",
    price: 300,
    date: "2026-10-06",
    time: "10:00",
    consumer_name: "Bruno Pérez",
    consumer_company: "GoGrow",
    menu_name: "Milanesa de pollo",
    address: "Av. 18 de Julio 1006",
    rejectable: true,
    ...overrides,
  }
}

describe("ProviderOrderCard", () => {
  it("no muestra el código del pedido", () => {
    render(<ProviderOrderCard order={order({})} onDecided={vi.fn()} />)

    expect(screen.queryByText(/PED-/)).not.toBeInTheDocument()
    expect(screen.queryByText(/#1/)).not.toBeInTheDocument()
  })

  it("ofrece rechazar y confirmar un pedido por revisar", () => {
    render(<ProviderOrderCard order={order({})} onDecided={vi.fn()} />)

    expect(screen.getAllByRole("button").map((b) => b.textContent)).toEqual([
      "Rechazar",
      "Confirmar",
    ])
  })

  it("ofrece solo rechazar un confirmado que todavía se puede rechazar", () => {
    render(
      <ProviderOrderCard
        order={order({ status: "confirmed" })}
        onDecided={vi.fn()}
      />,
    )

    expect(screen.getAllByRole("button").map((b) => b.textContent)).toEqual([
      "Rechazar",
    ])
  })

  it.each([
    ["confirmado histórico", "confirmed"],
    ["cancelado", "cancelled"],
    ["rechazado", "rejected"],
  ] as const)("termina en la dirección si es un %s", (_, status) => {
    const { container } = render(
      <ProviderOrderCard
        order={order({ status, rejectable: false })}
        onDecided={vi.fn()}
      />,
    )

    expect(screen.queryByRole("button")).not.toBeInTheDocument()
    expect(
      container.querySelector("[data-slot=card-footer]"),
    ).toBeEmptyDOMElement()
    expect(container.querySelector("[data-slot=card-footer]")).toHaveClass(
      "empty:hidden",
    )
  })
})
