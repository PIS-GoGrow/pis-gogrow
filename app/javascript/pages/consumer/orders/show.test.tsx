import { render, screen, within } from "@testing-library/react"
import { describe, expect, it, vi } from "vitest"

import type { Order } from "@/types"

import Show from "./show"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Head: () => null,
    usePage: () => ({ props: { locale: "es" } }),
    Link: ({
      children,
      href,
      ...props
    }: {
      children: React.ReactNode
      href: string | { url: string }
    }) => (
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

describe("Consumer::Orders Show Page", () => {
  const baseOrder: Order = {
    id: 1,
    status: "confirmed",
    delivery_method: "office",
    amount: 2,
    notes: "Sin sal",
    address: "18 de Julio 1006",
    rejection_details: null,
    date: "2026-10-15",
    menu_name: "Milanesa Napolitana",
    provider_name: "TuViandita",
    price: 500,
    subsidy: 250,
    discounted_price: 250,
    cancellable: true,
    modifiable: true,
  }

  const deliveryAddresses = [
    { id: "1", label: "Oficina", address: "18 de Julio 1006" },
  ]

  it("renders order information correctly", () => {
    render(
      <Show
        order={baseOrder}
        delivery_addresses={deliveryAddresses}
        max_quantity={5}
        editing={false}
      />,
    )

    expect(screen.getByText("TuViandita")).toBeInTheDocument()
    expect(screen.getByText("Milanesa Napolitana")).toBeInTheDocument()
    expect(screen.getByText("18 de Julio 1006")).toBeInTheDocument()
    expect(screen.getByText("Sin sal")).toBeInTheDocument()
    expect(screen.queryByText("Motivo de rechazo")).not.toBeInTheDocument()
  })

  it("displays rejection reason when order is rejected with standard reason", () => {
    const rejectedOrder: Order = {
      ...baseOrder,
      status: "rejected",
      rejection_reason: "out_of_stock",
      cancellable: false,
      cancellation_block_reason: "already_closed",
      modifiable: false,
      modification_block_reason: "already_confirmed",
    }

    render(
      <Show
        order={rejectedOrder}
        delivery_addresses={deliveryAddresses}
        max_quantity={5}
        editing={false}
      />,
    )

    expect(screen.getByText("Motivo de rechazo")).toBeInTheDocument()
    expect(screen.getByText("Sin stock disponible")).toBeInTheDocument()
  })

  it("displays custom rejection details when reason is 'other'", () => {
    const rejectedOrder: Order = {
      ...baseOrder,
      status: "rejected",
      rejection_reason: "other",
      rejection_details: "El local se encuentra cerrado por reformas",
      cancellable: false,
      cancellation_block_reason: "already_closed",
      modifiable: false,
      modification_block_reason: "already_confirmed",
    }

    render(
      <Show
        order={rejectedOrder}
        delivery_addresses={deliveryAddresses}
        max_quantity={5}
        editing={false}
      />,
    )

    expect(screen.getByText("Motivo de rechazo")).toBeInTheDocument()
    expect(
      screen.getByText("El local se encuentra cerrado por reformas"),
    ).toBeInTheDocument()
  })

  it("renders edit dialog open when editing is true", () => {
    render(
      <Show
        order={baseOrder}
        delivery_addresses={deliveryAddresses}
        max_quantity={5}
        editing={true}
      />,
    )

    const dialog = screen.getByRole("dialog")
    expect(dialog).toBeInTheDocument()
    expect(
      within(dialog).getByRole("heading", { name: "Modificar pedido" }),
    ).toBeInTheDocument()
  })
})
