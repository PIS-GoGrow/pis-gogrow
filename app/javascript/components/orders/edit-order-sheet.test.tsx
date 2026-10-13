import { render, screen } from "@testing-library/react"
import { describe, expect, it, vi } from "vitest"

import type { ConsumerOrdersShow, Order } from "@/types"

import EditOrderSheet from "./edit-order-sheet"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    useForm: (initialValues: unknown) => ({
      data: initialValues as Record<string, unknown>,
      setData: vi.fn(),
      patch: vi.fn(),
      processing: false,
      transform: vi.fn(),
    }),
  }
})

describe("EditOrderSheet", () => {
  const baseOrder: Order = {
    id: 1,
    status: "pending",
    delivery_method: "office",
    amount: 1,
    notes: "Nota inicial",
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
    selected_options: [],
  }

  const addresses: ConsumerOrdersShow["delivery_addresses"] = [
    { id: "1", label: "Oficina", address: "18 de Julio 1006" },
  ]

  it("renders textarea with maxLength 140 and character counter", () => {
    render(
      <EditOrderSheet
        order={baseOrder}
        addresses={addresses}
        optionGroups={[]}
        maxQuantity={5}
        editing={true}
      />,
    )

    const textarea = screen.getByRole("textbox", { name: "Notas" })
    expect(textarea).toBeInTheDocument()
    expect(textarea).toHaveAttribute("maxLength", "140")
    expect(textarea).toHaveAttribute("placeholder", "Sin salsa, sin cebolla…")
    expect(screen.getByText("12/140")).toBeInTheDocument()
  })

  it("shows 0/140 when order has no notes", () => {
    const orderWithoutNotes: Order = {
      ...baseOrder,
      notes: null,
    }

    render(
      <EditOrderSheet
        order={orderWithoutNotes}
        addresses={addresses}
        optionGroups={[]}
        maxQuantity={5}
        editing={true}
      />,
    )

    expect(screen.getByText("0/140")).toBeInTheDocument()
  })
})
