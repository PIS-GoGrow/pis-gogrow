import { render, screen, within } from "@testing-library/react"
import type React from "react"
import { describe, expect, it, vi } from "vitest"

import type { AdminOrderEvent } from "@/types/serializers"

import Index from "./index"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Head: () => null,
    Form: ({ children }: { children: React.ReactNode }) => (
      <form>{children}</form>
    ),
    Link: ({
      children,
      href,
      ...props
    }: Omit<React.ComponentProps<"a">, "href"> & {
      href?: string | { url: string }
    }) => (
      <a href={typeof href === "string" ? href : href?.url} {...props}>
        {children}
      </a>
    ),
    usePage: () => ({ props: { locale: "es" } }),
  }
})

vi.mock("@/layouts/app-layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="app-layout">{children}</div>
  ),
}))

// Historia: "Como RR.HH., quiero disponer de un registro de auditoría de todos
// los cambios realizados en los pedidos, para poder resolver cualquier disputa
// sobre si una comida fue solicitada o si corresponde cobrarla."
describe("Admin::OrderEvents Index Page", () => {
  const event: AdminOrderEvent = {
    id: 1,
    order_id: 42,
    action: "modified",
    role: "consumer",
    occurred_at: "21/10/2026 10:15:00",
    actor_name: "Sofía",
    consumer_name: "Sofía",
    dish: "Milanesa",
    changes: [
      { field: "amount", before: "1", after: "2" },
      { field: "notes", before: null, after: "Sin sal" },
    ],
  }

  it("shows the order, when, who, with which role and every value that changed", () => {
    render(<Index events={[event]} total={1} filters={{}} />)

    const first = screen.getByRole("row", { name: /PED-42/ })
    expect(within(first).getByText("21/10/2026 10:15:00")).toBeInTheDocument()
    expect(within(first).getByText("Empleado")).toBeInTheDocument()
    expect(within(first).getByText("Modificación")).toBeInTheDocument()
    expect(within(first).getByText("Cantidad")).toBeInTheDocument()

    const second = screen.getByRole("row", { name: /Notas/ })
    expect(within(second).getByText("—")).toBeInTheDocument()
    expect(within(second).getByText("Sin sal")).toBeInTheDocument()
  })

  it("names the system as the actor of a change made without a session", () => {
    render(
      <Index
        events={[{ ...event, actor_name: undefined, role: null }]}
        total={1}
        filters={{}}
      />,
    )

    expect(screen.getByText("Sistema")).toBeInTheDocument()
  })

  it("offers no action to edit or delete an event", () => {
    render(<Index events={[event]} total={1} filters={{}} />)

    const table = screen.getByRole("table")
    expect(within(table).queryByRole("button")).not.toBeInTheDocument()
  })

  it("goes back to the account like the other account screens", () => {
    render(<Index events={[event]} total={1} filters={{}} />)

    expect(
      screen.getByRole("link", { name: "Volver a Cuenta" }),
    ).toHaveAttribute("href", "/rrhh/cuenta")
  })

  it("warns when only the most recent events are shown", () => {
    render(<Index events={[event]} total={350} filters={{}} />)

    expect(screen.getByText(/de 350/)).toBeInTheDocument()
  })

  it("says so when nothing matches", () => {
    render(<Index events={[]} total={0} filters={{}} />)

    expect(screen.getByText("No hay eventos")).toBeInTheDocument()
  })
})
