import { render, screen, within } from "@testing-library/react"
import type React from "react"
import { describe, expect, it, vi } from "vitest"

import type { AdminDashboardIndex } from "@/types/serializers"

import AdminDashboard from "./index"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Head: () => null,
    usePage: () => ({
      url: "/admin/dashboard",
      props: { locale: "es", auth: { user: { name: "Juan Pérez" } } },
    }),
  }
})

vi.mock("@/layouts/app-layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="app-layout">{children}</div>
  ),
}))

vi.mock("@/components/admin/admin-mobile-nav", () => ({
  AdminMobileNav: () => null,
}))

const props: AdminDashboardIndex = {
  today: "Jueves 1 de octubre",
  month: "2026-10",
  current_month: "2026-10",
  months: [
    { key: "2026-10", label: "Octubre 2026" },
    { key: "2026-09", label: "Septiembre 2026" },
  ],
  summary: {
    meals: 45,
    meals_limit: 300,
    participation: 72,
    spending: 5425,
    paid: 2325,
    pending: 3100,
    projected: 0,
  },
  payment_month: "septiembre",
  payments: [
    { name: "Endulzate by Noe", amount: 2325, status: "approved" },
    { name: "Tu Viandita", amount: 1550, status: "pending" },
  ],
  debtors: [
    {
      id: 7,
      name: "Martín Bonnet",
      email: "martin@gogrow.com",
      amount: 2425,
      status: "pending",
    },
  ],
}

// Historia IBP-032: "Como RR. HH., quiero consultar un resumen general del mes
// con información del beneficio, participación, consumos, gasto y presupuesto,
// para conocer el estado global del programa."
describe("Admin Dashboard Page", () => {
  it("greets HR by first name with today's date", () => {
    render(<AdminDashboard {...props} />)

    expect(
      screen.getByRole("heading", { name: /Hola, Juan/ }),
    ).toBeInTheDocument()
    expect(screen.getByText("Jueves 1 de octubre")).toBeInTheDocument()
  })

  it("summarizes the benefit of the selected month", () => {
    render(<AdminDashboard {...props} />)

    expect(screen.getByText("Tu beneficio")).toBeInTheDocument()
    expect(screen.getByText("45 de 300")).toBeInTheDocument()
    expect(screen.getByText("viandas pedidas")).toBeInTheDocument()
    expect(screen.getByText("72%")).toBeInTheDocument()
    expect(screen.getByText("$5.425")).toBeInTheDocument()
    expect(screen.getByRole("progressbar")).toBeInTheDocument()
    expect(screen.getByText(/Pagado/)).toBeInTheDocument()
    expect(screen.queryByText(/Proyectado/)).not.toBeInTheDocument()
    expect(
      screen.getByRole("combobox", { name: "Mes del resumen" }),
    ).toHaveTextContent("Este mes")
    expect(
      screen.getByRole("link", { name: "Ver detalle del consumo" }),
    ).toHaveAttribute("href", "/admin/payments?month=2026-10")
  })

  it("shows the meals alone when the month had no benefit configured", () => {
    render(
      <AdminDashboard
        {...props}
        summary={{ ...props.summary, meals: 1, meals_limit: null }}
      />,
    )

    expect(screen.getByText("1")).toBeInTheDocument()
    expect(screen.getByText("vianda pedida")).toBeInTheDocument()
    expect(screen.queryByRole("progressbar")).not.toBeInTheDocument()
  })

  it("lists the payments to each provider with their status", () => {
    render(<AdminDashboard {...props} />)

    const payments = screen.getByRole("region", {
      name: "Tus pagos de septiembre",
    })
    expect(within(payments).getByText("Endulzate by Noe")).toBeInTheDocument()
    expect(within(payments).getByText("Confirmado")).toBeInTheDocument()
    expect(within(payments).getByText("Pendiente")).toBeInTheDocument()
    expect(
      within(payments).getByRole("link", { name: "Ver pagos a proveedores" }),
    ).toHaveAttribute("href", "/admin/payments")
  })

  it("links the debt ranking to each employee and to the pending ones", () => {
    render(<AdminDashboard {...props} />)

    const debts = screen.getByRole("region", {
      name: "Ranking deuda de empleados",
    })
    expect(
      within(debts).getByRole("link", { name: "Martín Bonnet" }),
    ).toHaveAttribute("href", "/admin/consumers/7")
    expect(
      within(debts).getByRole("link", {
        name: "Ver empleados con saldos pendientes",
      }),
    ).toHaveAttribute("href", "/admin/consumers?filter=pending")
  })

  it("shows an empty state instead of figures from another month", () => {
    render(
      <AdminDashboard
        {...props}
        summary={{
          meals: 0,
          meals_limit: 300,
          participation: 0,
          spending: 0,
          paid: 0,
          pending: 0,
          projected: 0,
        }}
        payments={[]}
        debtors={[]}
      />,
    )

    expect(screen.getByText("0 de 300")).toBeInTheDocument()
    expect(screen.getByText("0%")).toBeInTheDocument()
    expect(
      screen.getByText("No hay pagos a proveedores de septiembre."),
    ).toBeInTheDocument()
    expect(
      screen.getByText("Ningún empleado tiene saldos pendientes en este mes."),
    ).toBeInTheDocument()
  })
})
