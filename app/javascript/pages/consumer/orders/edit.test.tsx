import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it, vi } from "vitest"

import type { ConsumerOrdersEdit } from "@/types"

import Edit from "./edit"

const form = vi.hoisted(() => ({
  quantity: 3,
  patch: vi.fn(),
  transform: vi.fn(),
}))

vi.mock("@inertiajs/react", () => ({
  Head: () => null,
  router: { visit: vi.fn() },
  useForm: (initial: Record<string, unknown>) => ({
    data: { ...initial, quantity: form.quantity },
    setData: vi.fn(),
    patch: form.patch,
    processing: false,
    transform: form.transform,
  }),
}))
vi.mock("@/hooks/use-mobile", () => ({ useIsMobile: () => true }))
vi.mock("@/layouts/app-layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => <>{children}</>,
}))
vi.mock("@/pages/consumer/dashboard/dish-detail", () => ({
  DishDetail: ({ add }: { add: () => void }) => (
    <button onClick={add}>Modificar</button>
  ),
}))
vi.mock("@/components/orders/cancel-order-sheet", () => ({
  CancelOrderDialog: () => null,
}))
vi.mock("@/components/orders/order-updated-sheet", () => ({
  default: () => null,
}))

const props = {
  order: {
    id: 1,
    status: "confirmed",
    amount: 2,
    address: "18 de Julio 1006",
    notes: "",
    selected_options: [],
  },
  schedule: { menu: { home_delivery: false } },
  delivery_addresses: [],
  benefit_ids: [],
} as unknown as ConsumerOrdersEdit

function sentOrder() {
  const [transformer] = form.transform.mock.lastCall as [
    (data: Record<string, unknown>) => { order: Record<string, unknown> },
  ]
  return transformer({ quantity: form.quantity, selections: {} }).order
}

describe("Edit", () => {
  it("tells the server the employee accepted adding units", async () => {
    render(<Edit {...props} />)

    await userEvent.click(screen.getByRole("button", { name: "Modificar" }))
    await userEvent.click(
      await screen.findByRole("button", { name: "Aumentar pedido" }),
    )

    expect(sentOrder().add_units).toBe(true)
    expect(form.patch).toHaveBeenCalled()
  })

  it("does not when the employee accepted replacing the order", async () => {
    form.quantity = 1
    render(<Edit {...props} />)

    await userEvent.click(screen.getByRole("button", { name: "Modificar" }))
    await userEvent.click(
      await screen.findByRole("button", { name: "Modificar pedido" }),
    )

    expect(sentOrder().add_units).toBe(false)
  })
})
