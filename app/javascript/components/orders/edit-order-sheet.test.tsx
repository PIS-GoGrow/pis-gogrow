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

  it("applies max-h-[90dvh] and overflow-y-auto to dialog content for scrollability", () => {
    render(
      <EditOrderSheet
        order={baseOrder}
        addresses={addresses}
        optionGroups={[]}
        maxQuantity={5}
        editing={true}
      />,
    )

    const dialog = screen.getByRole("dialog")
    expect(dialog).toHaveClass("max-h-[90dvh]")
    expect(dialog).toHaveClass("overflow-y-auto")
  })

  it("renders customization option groups and their choices", () => {
    const optionGroups: ConsumerOrdersShow["option_groups"] = [
      {
        id: 1,
        name: "Salsa",
        options: ["Filetto", "Bolognesa"],
        limit: 1,
        required: true,
      },
      {
        id: 2,
        name: "Relleno",
        options: ["Ricota", "Espinaca"],
        limit: 1,
        required: false,
      },
    ]

    render(
      <EditOrderSheet
        order={{
          ...baseOrder,
          selected_options: [
            { group_id: 1, name: "Salsa", values: ["Filetto"] },
          ],
        }}
        addresses={addresses}
        optionGroups={optionGroups}
        maxQuantity={5}
        editing={true}
      />,
    )

    expect(screen.getByText("Filetto")).toBeInTheDocument()
    expect(screen.getByText("Bolognesa")).toBeInTheDocument()
    expect(screen.getByText("Ricota")).toBeInTheDocument()
    expect(screen.getByText("Espinaca")).toBeInTheDocument()
  })

  it("disables the submit button if a required option group has no selection", () => {
    const optionGroups: ConsumerOrdersShow["option_groups"] = [
      {
        id: 1,
        name: "Salsa",
        options: ["Filetto", "Bolognesa"],
        limit: 1,
        required: true,
      },
    ]

    render(
      <EditOrderSheet
        order={{
          ...baseOrder,
          selected_options: [],
        }}
        addresses={addresses}
        optionGroups={optionGroups}
        maxQuantity={5}
        editing={true}
      />,
    )

    const submitButton = screen.getByRole("button", { name: "Guardar cambios" })
    expect(submitButton).toBeDisabled()
  })

  it("enables the submit button when required option groups are satisfied", () => {
    const optionGroups: ConsumerOrdersShow["option_groups"] = [
      {
        id: 1,
        name: "Salsa",
        options: ["Filetto", "Bolognesa"],
        limit: 1,
        required: true,
      },
    ]

    render(
      <EditOrderSheet
        order={{
          ...baseOrder,
          selected_options: [
            { group_id: 1, name: "Salsa", values: ["Filetto"] },
          ],
        }}
        addresses={addresses}
        optionGroups={optionGroups}
        maxQuantity={5}
        editing={true}
      />,
    )

    const submitButton = screen.getByRole("button", { name: "Guardar cambios" })
    expect(submitButton).toBeEnabled()
  })
})
