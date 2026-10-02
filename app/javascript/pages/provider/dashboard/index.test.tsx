import { render, screen } from "@testing-library/react"
import type React from "react"
import { describe, expect, it, vi } from "vitest"

import ProviderDashboard from "./index"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Head: () => null,
    usePage: () => ({
      url: "/provider/dashboard",
      props: { auth: { user: { name: "Doña Petrona" } } },
    }),
    Link: ({
      children,
      href,
    }: {
      children: React.ReactNode
      href: string
    }) => <a href={href}>{children}</a>,
  }
})

vi.mock("@/layouts/app-layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="app-layout">{children}</div>
  ),
}))

describe("Provider Dashboard Page", () => {
  const defaultProps = {
    today: "Jueves, 1 de octubre",
    today_orders_count: 7,
    pending_orders_count: 2,
    office_orders_count: 3,
    home_orders_count: 1,
    order_deadline: "11:30",
    month_orders_count: 42,
    month_dishes_count: 8,
    average_rating: 4.8,
  }

  it("saluda al proveedor por su nombre y muestra la fecha del día", () => {
    render(<ProviderDashboard {...defaultProps} />)

    expect(
      screen.getByRole("heading", { name: /Hola, Doña Petrona/ }),
    ).toBeInTheDocument()
    expect(screen.getByText("Jueves, 1 de octubre")).toBeInTheDocument()
  })

  it("muestra el resumen de pedidos de hoy con confirmados, pendientes y modalidades", () => {
    render(<ProviderDashboard {...defaultProps} />)

    expect(screen.getByText("Confirmados")).toBeInTheDocument()
    // 7 total - 2 pendientes = 5 confirmados
    expect(screen.getByText("5")).toBeInTheDocument()

    expect(screen.getByText("Pendientes")).toBeInTheDocument()
    expect(screen.getByText("2")).toBeInTheDocument()

    expect(screen.getByText("Envío a oficina")).toBeInTheDocument()
    expect(screen.getByText("3")).toBeInTheDocument()

    expect(screen.getByText("Envío a domicilio")).toBeInTheDocument()
    expect(screen.getByText("1")).toBeInTheDocument()

    const viewOrdersLink = screen.getByRole("link", { name: "Ver pedidos" })
    expect(viewOrdersLink).toHaveAttribute("href", "/provider/orders")
  })

  it("muestra la hora de cierre si está configurada", () => {
    render(<ProviderDashboard {...defaultProps} order_deadline="11:30" />)

    expect(
      screen.getByText("Recibiendo pedidos hasta 11:30"),
    ).toBeInTheDocument()
  })

  it("muestra 'Próximamente' en la hora límite cuando no está configurada", () => {
    render(<ProviderDashboard {...defaultProps} order_deadline={null} />)

    expect(screen.getByText("Próximamente")).toBeInTheDocument()
  })

  it("muestra los hallazgos del mes con pedidos, platos y valoración", () => {
    render(<ProviderDashboard {...defaultProps} />)

    expect(screen.getByText("Hallazgos del mes")).toBeInTheDocument()
    expect(screen.getByText("42")).toBeInTheDocument()
    expect(screen.getByText("8")).toBeInTheDocument()
    expect(screen.getByText("4.8")).toBeInTheDocument()
  })

  it("muestra un guión cuando el proveedor aún no tiene valoraciones", () => {
    render(<ProviderDashboard {...defaultProps} average_rating={null} />)

    expect(screen.getByText("—")).toBeInTheDocument()
  })

  it("ofrece enlace directo al resumen de cobros", () => {
    render(<ProviderDashboard {...defaultProps} />)

    const paymentsLink = screen.getByRole("link", {
      name: "Resumen de cobros",
    })
    expect(paymentsLink).toHaveAttribute("href", "/provider/collections")
  })
})
