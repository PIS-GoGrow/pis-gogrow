import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import type React from "react"
import { describe, expect, it, vi } from "vitest"

import type { ProviderOrder } from "@/types"

import Index from "./index"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Head: () => null,
    usePage: () => ({ props: { locale: "es" } }),
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

vi.mock("@/layouts/app-layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="app-layout">{children}</div>
  ),
}))

const TODAY = "2026-10-06"

function order(overrides: Partial<ProviderOrder>): ProviderOrder {
  return {
    id: 1,
    status: "pending",
    amount: 1,
    notes: null,
    delivery_method: "office",
    price: 300,
    date: TODAY,
    time: "10:00",
    consumer_name: "Bruno Pérez",
    consumer_company: "GoGrow",
    menu_name: "Milanesa de pollo",
    address: "Av. 18 de Julio 1006",
    ...overrides,
  }
}

const upcoming = [
  order({ id: 1 }),
  order({
    id: 2,
    status: "confirmed",
    delivery_method: "home",
    consumer_name: "Matías Rodríguez",
    menu_name: "Wok de verduras",
  }),
  order({
    id: 3,
    status: "cancelled",
    consumer_name: "Camila Herrera",
    menu_name: "Focaccia crispy",
  }),
]

const past = [order({ id: 10, date: "2026-10-05", consumer_name: "Ana Gómez" })]

function renderPage() {
  return render(
    <Index today={TODAY} upcoming_orders={upcoming} past_orders={past} />,
  )
}

describe("Provider orders page", () => {
  it("muestra el título, los filtros y los pedidos de hoy", () => {
    renderPage()

    expect(screen.getByRole("heading", { name: "Pedidos" })).toBeInTheDocument()
    expect(screen.getByRole("tab", { name: "Próximos" })).toBeInTheDocument()
    expect(screen.getByRole("tab", { name: "Historial" })).toBeInTheDocument()
    expect(screen.getByRole("tab", { name: "Por revisar" })).toBeInTheDocument()
    expect(screen.getByRole("tab", { name: "Confirmados" })).toBeInTheDocument()
    expect(screen.getByRole("tab", { name: "Todos" })).toHaveAttribute(
      "aria-selected",
      "true",
    )
    expect(screen.getByText("Entregas:")).toBeInTheDocument()
    expect(
      screen.getByPlaceholderText("Buscar pedido, plato, consumidor..."),
    ).toBeInTheDocument()
    expect(screen.getByText("Bruno Pérez - GoGrow")).toBeInTheDocument()
    expect(screen.getByText("Camila Herrera - GoGrow")).toBeInTheDocument()
  })

  it("no ofrece exportar los pedidos todavía", () => {
    renderPage()

    expect(
      screen.queryByRole("button", { name: /exportar/i }),
    ).not.toBeInTheDocument()
  })

  it("muestra solo los pedidos por revisar", async () => {
    const user = userEvent.setup()
    renderPage()

    await user.click(screen.getByRole("tab", { name: "Por revisar" }))

    expect(screen.getByText("Bruno Pérez - GoGrow")).toBeInTheDocument()
    expect(
      screen.queryByText("Matías Rodríguez - GoGrow"),
    ).not.toBeInTheDocument()
    expect(
      screen.queryByText("Camila Herrera - GoGrow"),
    ).not.toBeInTheDocument()
  })

  it("cambia al historial", async () => {
    const user = userEvent.setup()
    renderPage()

    await user.click(screen.getByRole("tab", { name: "Historial" }))

    expect(screen.getByText("Ana Gómez - GoGrow")).toBeInTheDocument()
    expect(screen.queryByText("Bruno Pérez - GoGrow")).not.toBeInTheDocument()
  })

  it("mantiene los filtros al cambiar de pestaña", async () => {
    const user = userEvent.setup()
    renderPage()

    await user.type(
      screen.getByPlaceholderText("Buscar pedido, plato, consumidor..."),
      "zzz",
    )
    await user.click(screen.getByRole("tab", { name: "Historial" }))

    expect(
      screen.getByText("No tenés pedidos que coincidan con los filtros."),
    ).toBeInTheDocument()
  })

  it("busca entre los pedidos", async () => {
    const user = userEvent.setup()
    renderPage()

    await user.type(
      screen.getByPlaceholderText("Buscar pedido, plato, consumidor..."),
      "wok",
    )

    expect(screen.getByText("Matías Rodríguez - GoGrow")).toBeInTheDocument()
    expect(screen.queryByText("Bruno Pérez - GoGrow")).not.toBeInTheDocument()
  })

  it("filtra por tipo de entrega desde el sheet", async () => {
    const user = userEvent.setup()
    renderPage()

    await user.click(
      screen.getByRole("button", { name: "Filtrar por tipo de entrega" }),
    )
    await user.click(screen.getByLabelText("Domicilios"))
    await user.click(screen.getByRole("button", { name: "Aplicar" }))

    expect(screen.getByText("Domicilios")).toBeInTheDocument()
    expect(screen.getByText("Matías Rodríguez - GoGrow")).toBeInTheDocument()
    expect(screen.queryByText("Bruno Pérez - GoGrow")).not.toBeInTheDocument()
  })
})
