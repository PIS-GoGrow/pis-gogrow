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

  it("no muestra el cupo", () => {
    render(<Show order={order()} />)

    expect(screen.queryByText(/cupo/i)).not.toBeInTheDocument()
  })

  it("conserva el subsidio y el importe a cargo del empleado", () => {
    render(
      <Show
        order={order({
          price: 600.5,
          subsidy: 300.25,
          discounted_price: 300.25,
        })}
      />,
    )

    expect(screen.getByText("$600,50")).toBeInTheDocument()
    expect(screen.getByText("Subsidio")).toBeInTheDocument()
    expect(screen.getByText("-$300,25")).toBeInTheDocument()
    expect(screen.getByText("Paga el empleado")).toBeInTheDocument()
    expect(screen.getByText("$300,25")).toBeInTheDocument()
  })

  it("conserva un importe cero y distingue un importe desconocido", () => {
    const { rerender } = render(
      <Show order={order({ subsidy: 600, discounted_price: 0 })} />,
    )
    expect(screen.getByText("$0")).toBeInTheDocument()

    rerender(<Show order={order({ subsidy: null, discounted_price: null })} />)
    expect(screen.getByText("Importe no disponible")).toBeInTheDocument()
    expect(screen.queryByText("Subsidio")).not.toBeInTheDocument()
  })

  it("muestra el motivo y el detalle de un rechazo", () => {
    render(
      <Show
        order={order({
          status: "rejected",
          rejection_reason: "other",
          rejection_details: "Cerrado por reformas",
        })}
      />,
    )

    expect(screen.getByText("Motivo de rechazo")).toBeInTheDocument()
    expect(screen.getByText("Otro motivo")).toBeInTheDocument()
    expect(screen.getByText("Cerrado por reformas")).toBeInTheDocument()
    expect(screen.getByRole("button", { name: "Confirmar" })).toBeDisabled()
    expect(screen.getByRole("button", { name: "Rechazar" })).toBeDisabled()
  })

  it("permite rechazar un pedido confirmado pero no confirmarlo otra vez", () => {
    render(<Show order={order({ status: "confirmed" })} />)

    expect(
      screen.getByText("Confirmado").closest("[data-status]"),
    ).toHaveAttribute("data-status", "confirmed")
    expect(screen.getByRole("button", { name: "Confirmar" })).toBeDisabled()
    expect(screen.getByRole("button", { name: "Rechazar" })).toBeEnabled()
  })

  it("conserva elecciones históricas aunque el plato ya no ofrezca el grupo", () => {
    render(
      <Show
        order={order({
          menu_option_groups: [],
          selected_options: [
            { group_id: 5, name: "Guarnición", values: ["Papas"] },
          ],
        })}
      />,
    )
    expect(screen.getByText("Guarnición")).toBeInTheDocument()
    expect(screen.getByText("Papas")).toBeInTheDocument()
  })
  it("no inventa elecciones para un pedido antiguo sin personalizaciones", () => {
    render(
      <Show
        order={order({
          menu_option_groups: [
            { id: 1, name: "Salsa", options: ["Tuco"], limit: 1 },
          ],
          selected_options: [],
        })}
      />,
    )

    expect(screen.getByText("Wok de verduras + arroz")).toBeInTheDocument()
    expect(screen.queryByText("Salsa")).not.toBeInTheDocument()
    expect(screen.queryByText("Tuco")).not.toBeInTheDocument()
    expect(screen.getByRole("button", { name: "Confirmar" })).toBeEnabled()
  })

  it("muestra un rechazo predefinido aunque no tenga detalles", () => {
    render(
      <Show
        order={order({
          status: "rejected",
          rejection_reason: "out_of_stock",
          rejection_details: null,
        })}
      />,
    )

    expect(
      screen.getByText("Rechazado").closest("[data-status]"),
    ).toHaveAttribute("data-status", "rejected")
    expect(screen.getByText("Sin stock disponible")).toBeInTheDocument()
    expect(screen.queryByText("Detalle del rechazo")).not.toBeInTheDocument()
  })
  it.each([null, ""])(
    "omite notas y descripción ausentes (%s) sin perder los datos del pedido",
    (value) => {
      render(
        <Show
          order={order({ notes: value, menu_description: value, date: null })}
        />,
      )

      expect(screen.getByText("Wok de verduras + arroz")).toBeInTheDocument()
      expect(screen.getByText("Pedido PED-1")).toBeInTheDocument()
      expect(screen.queryByText("Notas")).not.toBeInTheDocument()
      expect(screen.queryByText("Entrega")).not.toBeInTheDocument()
      expect(screen.queryByText("Sin sal")).not.toBeInTheDocument()
      expect(screen.queryByText("Con salsa de soja")).not.toBeInTheDocument()
    },
  )

  it("presenta los totales del backend sin multiplicarlos otra vez por la cantidad", () => {
    render(
      <Show
        order={order({
          amount: 3,
          price: 1234.56,
          discounted_price: 234.56,
          subsidy: 1000,
        })}
      />,
    )

    expect(screen.getByText("x3")).toBeInTheDocument()
    expect(screen.getByText("Total").parentElement).toHaveTextContent(
      "$1.234,56",
    )
    expect(
      screen.getByText("Paga el empleado").parentElement,
    ).toHaveTextContent("$234,56")
    expect(screen.getByText("Subsidio").parentElement).toHaveTextContent(
      "-$1.000",
    )
    expect(screen.queryByText("$3.703,68")).not.toBeInTheDocument()
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

    const confirm = screen.getByRole("button", { name: "Confirmar" })
    const reject = screen.getByRole("button", { name: "Rechazar" })
    expect(confirm).toBeEnabled()
    expect(reject).toBeEnabled()
    expect(screen.getAllByRole("button")).toEqual([confirm, reject])
  })

  it("deja los botones a la vista, deshabilitados, en un pedido cancelado", () => {
    render(<Show order={order({ status: "cancelled" })} />)

    expect(screen.getByRole("button", { name: "Confirmar" })).toBeDisabled()
    expect(screen.getByRole("button", { name: "Rechazar" })).toBeDisabled()
  })
})
