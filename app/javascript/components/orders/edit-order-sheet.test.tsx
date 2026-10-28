import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { useState } from "react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import type { ConsumerOrdersShow, Order } from "@/types"

import EditOrderSheet from "./edit-order-sheet"

const { patch, visit, cancel } = vi.hoisted(() => ({
  patch: vi.fn(),
  visit: vi.fn(),
  cancel: vi.fn(),
}))

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    router: { visit, patch: cancel },
    useForm: (initialValues: Record<string, unknown>) => {
      const [data, setFormData] = useState(initialValues)
      return {
        data,
        setData: (key: string, value: unknown) =>
          setFormData((previous) => ({ ...previous, [key]: value })),
        patch,
        processing: false,
        transform: vi.fn(),
      }
    },
  }
})

describe("EditOrderSheet", () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

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
    reviewable: false,
    reviewed: false,
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

    const submitButton = screen.getByRole("button", { name: "Modificar" })
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

    const submitButton = screen.getByRole("button", { name: "Modificar" })
    expect(submitButton).toBeEnabled()
  })

  describe("address rendering matching cart behavior", () => {
    it("renders office and the selected custom address", () => {
      const multipleAddresses: ConsumerOrdersShow["delivery_addresses"] = [
        { id: "office", label: "Oficina", address: "18 de Julio 1006" },
        { id: "home-1", label: "Casa", address: "Julio Herrera y Reissig 565" },
        { id: "home-2", label: "Padres", address: "Bulevar Artigas 1234" },
      ]

      render(
        <EditOrderSheet
          order={{
            ...baseOrder,
            address: "Julio Herrera y Reissig 565",
          }}
          addresses={multipleAddresses}
          optionGroups={[]}
          maxQuantity={5}
          editing={true}
        />,
      )

      expect(screen.getByText("18 de Julio 1006")).toBeInTheDocument()
      expect(
        screen.getByText("Julio Herrera y Reissig 565"),
      ).toBeInTheDocument()
      expect(screen.queryByText("Bulevar Artigas 1234")).not.toBeInTheDocument()
      expect(
        screen.getByRole("button", { name: /Ver mis direcciones/i }),
      ).toBeInTheDocument()
    })

    it("does not render the saved addresses sheet button when there is only one custom address", () => {
      const singleCustomAddress: ConsumerOrdersShow["delivery_addresses"] = [
        { id: "office", label: "Oficina", address: "18 de Julio 1006" },
        { id: "home-1", label: "Casa", address: "Julio Herrera y Reissig 565" },
      ]

      render(
        <EditOrderSheet
          order={baseOrder}
          addresses={singleCustomAddress}
          optionGroups={[]}
          maxQuantity={5}
          editing={true}
        />,
      )

      expect(
        screen.queryByRole("button", { name: /Ver mis direcciones/i }),
      ).not.toBeInTheDocument()
    })

    it("never renders remaining stock message even with small maxQuantity", () => {
      render(
        <EditOrderSheet
          order={baseOrder}
          addresses={addresses}
          optionGroups={[]}
          maxQuantity={2}
          editing={true}
        />,
      )

      expect(screen.queryByText(/disponibles/i)).not.toBeInTheDocument()
    })
  })

  describe("modifying", () => {
    // El patch real redirige y llama a onSuccess con la página nueva; sin
    // alerta, el cambio se guardó.
    const succeed = () =>
      patch.mockImplementation(
        (_url: string, options: { onSuccess: (page: unknown) => void }) =>
          options.onSuccess({ props: {}, flash: {} }),
      )

    const renderSheet = (order: Partial<Order> = {}, editing = true) =>
      render(
        <EditOrderSheet
          order={{ ...baseOrder, ...order }}
          addresses={addresses}
          optionGroups={[]}
          maxQuantity={5}
          editing={editing}
        />,
      )

    it("shows the dish, its provider and its status", () => {
      renderSheet({ status: "confirmed" })

      expect(
        screen.getByRole("heading", { name: "Milanesa Napolitana" }),
      ).toBeInTheDocument()
      expect(screen.getByText("TuViandita")).toBeInTheDocument()
      expect(screen.getByText("Confirmado")).toBeInTheDocument()
    })

    it("saves a pending order without asking and then confirms it was modified", async () => {
      succeed()
      renderSheet()

      await userEvent.click(screen.getByRole("button", { name: "Agregar uno" }))
      await userEvent.click(screen.getByRole("button", { name: "Modificar" }))

      expect(patch).toHaveBeenCalledOnce()
      expect(screen.getByText("Pedido modificado")).toBeInTheDocument()
      expect(
        screen.getByText(
          "Te notificaremos cuando el proveedor confirme tu pedido.",
        ),
      ).toBeInTheDocument()
    })

    it("does not let a confirmed order be submitted without changes", () => {
      renderSheet({ status: "confirmed" })

      expect(screen.getByRole("button", { name: "Modificar" })).toBeDisabled()
    })

    it("asks before adding units to a confirmed order", async () => {
      succeed()
      renderSheet({ status: "confirmed" })

      await userEvent.click(screen.getByRole("button", { name: "Agregar uno" }))
      await userEvent.click(screen.getByRole("button", { name: "Modificar" }))

      expect(screen.getByText("¿Agregar más unidades?")).toBeInTheDocument()
      expect(patch).not.toHaveBeenCalled()

      await userEvent.click(
        screen.getByRole("button", { name: "Aumentar pedido" }),
      )

      expect(patch).toHaveBeenCalledOnce()
      expect(screen.getByText("Pedido modificado")).toBeInTheDocument()
    })

    it("warns that changing other details of a confirmed order reorders it", async () => {
      renderSheet({ status: "confirmed" })

      await userEvent.type(screen.getByRole("textbox", { name: "Notas" }), "!")
      await userEvent.click(screen.getByRole("button", { name: "Modificar" }))

      expect(screen.getByText("¿Modificar el pedido?")).toBeInTheDocument()

      await userEvent.click(screen.getByRole("button", { name: "Volver" }))

      expect(screen.getByRole("textbox", { name: "Notas" })).toHaveValue(
        "Nota inicial!",
      )
      expect(patch).not.toHaveBeenCalled()
    })

    it("goes back to the order list when it was opened from there", async () => {
      renderSheet({}, true)

      await userEvent.click(screen.getByRole("button", { name: "Volver" }))

      expect(visit).toHaveBeenCalledWith("/pedidos", { replace: true })
    })

    it("returns to the order list after a modification opened from there", async () => {
      succeed()
      renderSheet({}, true)

      await userEvent.click(screen.getByRole("button", { name: "Modificar" }))
      await userEvent.click(screen.getByRole("button", { name: "Listo" }))

      expect(visit).toHaveBeenCalledWith("/pedidos", { replace: true })
    })

    it("stays on the order detail when it was opened from there", async () => {
      succeed()
      renderSheet({}, false)

      await userEvent.click(screen.getByRole("button", { name: "Editar" }))
      await userEvent.click(screen.getByRole("button", { name: "Modificar" }))
      await userEvent.click(screen.getByRole("button", { name: "Listo" }))

      expect(visit).toHaveBeenCalledWith("/pedidos/1", {
        replace: true,
      })
    })

    it("asks to cancel the order from the quantity's trash button", async () => {
      renderSheet()

      await userEvent.click(
        screen.getByRole("button", { name: "Cancelar pedido" }),
      )

      expect(screen.getByText("¿Cancelar pedido?")).toBeInTheDocument()

      await userEvent.click(
        screen.getByRole("button", { name: "Cancelar pedido" }),
      )

      expect(cancel).toHaveBeenCalledOnce()
    })
  })
})
