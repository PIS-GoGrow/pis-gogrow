import { render, screen } from "@testing-library/react"
import type React from "react"
import { describe, expect, it, vi } from "vitest"

import type { ProviderOrderDetail } from "@/types"

import Show from "./show"

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

function order(overrides: Partial<ProviderOrderDetail> = {}) {
  const base: ProviderOrderDetail = {
    id: 1,
    status: "pending",
    amount: 2,
    notes: "Sin sal",
    delivery_method: "office",
    price: 600,
    date: "2026-10-15",
    time: "10:15",
    consumer_name: "Matías Rodríguez",
    consumer_company: "GoGrow",
    menu_name: "Wok de verduras + arroz",
    address: "Av. 18 de Julio 1234, Centro",
    consumer_email: "matias.rodriguez@gogrow.dev",
    created_on: "2026-09-11",
    menu_description: "Con salsa de soja",
    menu_option_groups: [],
    selected_options: [],
    discounted_price: 300,
    subsidy: 300,
    schedule_amount: 10,
    remaining_amount: 8,
    rejection_reason: null,
    rejection_details: null,
  }

  return { ...base, ...overrides }
}

describe("Provider::Orders Show Page", () => {
  it("encabeza con el estado, el código y cuándo se hizo el pedido", () => {
    render(<Show order={order()} />)

    expect(
      screen.getByRole("heading", { name: "Detalle de pedido" }),
    ).toBeInTheDocument()
    expect(
      screen.getByText("Por revisar").closest("[data-status]"),
    ).toHaveAttribute("data-status", "pending")
    expect(screen.getByText("Pedido PED-1")).toBeInTheDocument()
    expect(
      screen.getByText("11 de septiembre de 2026 · 10:15"),
    ).toBeInTheDocument()
  })

  it("muestra los datos del empleado y deja el teléfono como no disponible", () => {
    render(<Show order={order()} />)

    expect(screen.getByText("Empleado GoGrow")).toBeInTheDocument()
    expect(screen.getByText("Matías Rodríguez")).toBeInTheDocument()
    expect(screen.getByText("matias.rodriguez@gogrow.dev")).toBeInTheDocument()
    expect(screen.getByText("No disponible")).toBeInTheDocument()
    expect(
      screen.getByText("Oficina · Av. 18 de Julio 1234, Centro"),
    ).toBeInTheDocument()
  })

  it("muestra el plato, la cantidad y el total", () => {
    render(<Show order={order()} />)

    expect(screen.getByText("Detalle del pedido")).toBeInTheDocument()
    expect(screen.getByText("Wok de verduras + arroz")).toBeInTheDocument()
    expect(screen.getByText("x2")).toBeInTheDocument()
    expect(screen.getByText("Total")).toBeInTheDocument()
    expect(screen.getByText("$600")).toBeInTheDocument()
  })

  it("completa el detalle con la descripción, las notas y la fecha de entrega", () => {
    render(<Show order={order()} />)

    expect(screen.getByText("Con salsa de soja")).toBeInTheDocument()
    expect(screen.getByText("Sin sal")).toBeInTheDocument()
    expect(screen.getByText("15 de octubre de 2026")).toBeInTheDocument()
  })

  it("muestra lo que el empleado eligió del plato", () => {
    render(
      <Show
        order={order({
          selected_options: [
            { group_id: 1, name: "Salsas", values: ["Tuco", "Blanca"] },
            { group_id: 2, name: "Rellenos", values: [] },
          ],
        })}
      />,
    )

    expect(screen.getByText("Salsas")).toBeInTheDocument()
    expect(screen.getByText("Tuco · Blanca")).toBeInTheDocument()
    expect(screen.queryByText("Rellenos")).not.toBeInTheDocument()
  })

  it("no muestra el cupo ni el subsidio", () => {
    render(<Show order={order()} />)

    expect(screen.queryByText(/cupo/i)).not.toBeInTheDocument()
    expect(screen.queryByText(/subsidio/i)).not.toBeInTheDocument()
  })

  it("rotula solo «Empleado» cuando no hay empresa", () => {
    render(<Show order={order({ consumer_company: null })} />)

    expect(screen.getByText("Empleado")).toBeInTheDocument()
    expect(screen.queryByText(/Empleado GoGrow/)).not.toBeInTheDocument()
  })

  it("indica la entrega a domicilio y la falta de dirección", () => {
    render(<Show order={order({ delivery_method: "home", address: null })} />)

    expect(
      screen.getByText("Casa · Sin dirección de entrega"),
    ).toBeInTheDocument()
  })

  it("deja confirmar o rechazar un pedido por revisar", () => {
    render(<Show order={order()} />)

    expect(screen.getByRole("button", { name: "Confirmar" })).toBeEnabled()
    expect(screen.getByRole("button", { name: "Rechazar" })).toBeEnabled()
  })

  it("deja los botones a la vista, deshabilitados, en un pedido cancelado", () => {
    render(<Show order={order({ status: "cancelled" })} />)

    expect(screen.getByRole("button", { name: "Confirmar" })).toBeDisabled()
    expect(screen.getByRole("button", { name: "Rechazar" })).toBeDisabled()
  })
})
