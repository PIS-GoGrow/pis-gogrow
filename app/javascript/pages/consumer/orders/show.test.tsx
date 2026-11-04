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
    reviewable: false,
    reviewed: false,
    selected_options: [],
  }

  it("renders order information correctly", () => {
    render(<Show order={baseOrder} />)

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
      modification_block_reason: "already_closed",
    }

    render(<Show order={rejectedOrder} />)

    expect(screen.getByText("Motivo de rechazo")).toBeInTheDocument()
    expect(screen.getByText("Sin stock disponible")).toBeInTheDocument()
  })

  it("displays the unit price instead of the total base price", () => {
    const multipleOrder: Order = {
      ...baseOrder,
      amount: 2,
      price: 600,
      subsidy: 100,
      discounted_price: 500,
    }

    render(<Show order={multipleOrder} />)

    const priceRow = screen.getByText("Precio base").closest("div")

    expect(priceRow).not.toBeNull()
    expect(within(priceRow!).getByText("$300")).toBeInTheDocument()
  })

  it("displays the single unit price when order has amount 1", () => {
    const singleOrder: Order = {
      ...baseOrder,
      amount: 1,
      price: 300,
    }

    render(<Show order={singleOrder} />)

    const priceRow = screen.getByText("Precio base").closest("div")
    expect(priceRow).not.toBeNull()
    expect(within(priceRow!).getByText("$300")).toBeInTheDocument()
  })

  it("formats decimal unit prices with cents properly", () => {
    const decimalOrder: Order = {
      ...baseOrder,
      amount: 2,
      price: 601,
      subsidy: 300.5,
      discounted_price: 300.5,
    }

    render(<Show order={decimalOrder} />)

    const priceRow = screen.getByText("Precio base").closest("div")
    expect(priceRow).not.toBeNull()
    expect(within(priceRow!).getByText("$300,50")).toBeInTheDocument()
  })

  it("displays fallback text when price is missing or amount is zero", () => {
    const noPriceOrder: Order = {
      ...baseOrder,
      price: undefined,
      amount: 2,
    }

    const { rerender } = render(<Show order={noPriceOrder} />)

    let priceRow = screen.getByText("Precio base").closest("div")
    expect(priceRow).not.toBeNull()
    expect(
      within(priceRow!).getByText("Importe no disponible"),
    ).toBeInTheDocument()

    const zeroAmountOrder: Order = {
      ...baseOrder,
      price: 500,
      amount: 0,
    }

    rerender(<Show order={zeroAmountOrder} />)
    priceRow = screen.getByText("Precio base").closest("div")
    expect(priceRow).not.toBeNull()
    expect(
      within(priceRow!).getByText("Importe no disponible"),
    ).toBeInTheDocument()
    expect(within(priceRow!).queryByText("NaN")).not.toBeInTheDocument()
    expect(within(priceRow!).queryByText("Infinity")).not.toBeInTheDocument()
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
      modification_block_reason: "already_closed",
    }

    render(<Show order={rejectedOrder} />)

    expect(screen.getByText("Motivo de rechazo")).toBeInTheDocument()
    expect(
      screen.getByText("El local se encuentra cerrado por reformas"),
    ).toBeInTheDocument()
  })

  it("links to the edit page when the order is modifiable", () => {
    render(<Show order={baseOrder} />)

    expect(screen.getByRole("link", { name: /Editar/i })).toHaveAttribute(
      "href",
      "/pedidos/1/editar",
    )
  })

  it("does not show block reason texts when order is confirmed and shows disabled buttons", () => {
    const confirmedOrder: Order = {
      ...baseOrder,
      status: "confirmed",
      cancellable: false,
      cancellation_block_reason: "confirmed_for_today",
      modifiable: false,
      modification_block_reason: "confirmed_for_today",
    }

    render(<Show order={confirmedOrder} />)

    expect(
      screen.queryByText(
        "Ya está confirmado para hoy, así que no se puede cancelar.",
      ),
    ).not.toBeInTheDocument()
    expect(
      screen.queryByText(
        "Ya está confirmado para hoy, así que no se puede modificar.",
      ),
    ).not.toBeInTheDocument()
    expect(screen.getByRole("button", { name: /Cancelar/i })).toBeDisabled()
    expect(screen.getByRole("button", { name: /Editar/i })).toBeDisabled()
  })

  it("displays block reason when pending order is past order deadline", () => {
    const closedPendingOrder: Order = {
      ...baseOrder,
      status: "pending",
      cancellable: false,
      cancellation_block_reason: "order_deadline_passed",
      modifiable: false,
      modification_block_reason: "already_closed",
    }

    render(<Show order={closedPendingOrder} />)

    expect(
      screen.getByText(
        "El proveedor ya cerró la recepción de pedidos de hoy, así que no se puede cancelar.",
      ),
    ).toBeInTheDocument()
    expect(screen.getByRole("button", { name: /Cancelar/i })).toBeDisabled()
  })

  it("renders long notes without spaces with text wrapping styling to prevent overflow", () => {
    const longNote = "a".repeat(140)
    const orderWithLongNote: Order = {
      ...baseOrder,
      notes: longNote,
    }

    render(<Show order={orderWithLongNote} />)

    const notesElement = screen.getByText(longNote)
    expect(notesElement).toBeInTheDocument()
    expect(notesElement).toHaveClass("[overflow-wrap:anywhere]")
  })
})
