import { render, screen, within } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import type React from "react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import AdminReports from "./index"

const { routerGet } = vi.hoisted(() => ({ routerGet: vi.fn() }))

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Head: () => null,
    usePage: () => ({ url: "/rrhh/reportes", props: { locale: "es" } }),
    router: { get: routerGet },
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

beforeEach(() => routerGet.mockClear())

// Historia IBP-043: "Como RR. HH., quiero consultar reportes y métricas
// adicionales sobre uso del beneficio, pedidos y pagos."
describe("Admin Reports Page", () => {
  const props = {
    from: "2026-10-01",
    to: "2026-10-31",
    default_from: "2026-10-01",
    default_to: "2026-10-31",
    min: "2026-06-15",
    max: "2026-10-31",
    month_label: "Octubre 2026",
    presets: [
      { key: "today" as const, from: "2026-10-25", to: "2026-10-25" },
      { key: "yesterday" as const, from: "2026-10-24", to: "2026-10-24" },
      { key: "this_week" as const, from: "2026-10-25", to: "2026-10-25" },
      { key: "this_month" as const, from: "2026-10-01", to: "2026-10-31" },
      { key: "last_month" as const, from: "2026-09-01", to: "2026-09-30" },
    ],
    summary: {
      adhesion: 48,
      participants: 12,
      employees: 25,
      orders: 30,
      meals: 41,
      company_amount: 6150,
      employee_amount: 4100,
    },
    providers: [
      {
        id: 2,
        name: "Tu Viandita",
        orders: 20,
        meals: 28,
        company_amount: 4200,
      },
      {
        id: 1,
        name: "Endulzate by Noe",
        orders: 10,
        meals: 13,
        company_amount: 1950,
      },
    ],
  }

  it("muestra el título, el volver al Inicio y el período elegido", () => {
    render(<AdminReports {...props} />)

    expect(
      screen.getByRole("heading", { name: "Reportes" }),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("link", { name: "Volver al inicio" }),
    ).toHaveAttribute("href", "/rrhh/inicio")
    expect(screen.getByRole("button", { name: "Período" })).toHaveTextContent(
      "Octubre 2026",
    )
  })

  it("muestra la adhesión, los pedidos y el gasto acumulado", () => {
    render(<AdminReports {...props} />)

    expect(screen.getByText("Adhesión")).toBeInTheDocument()
    expect(screen.getByText("48%")).toBeInTheDocument()
    expect(screen.getByText("12 de 25 empleados")).toBeInTheDocument()
    expect(screen.getByText("Pedidos")).toBeInTheDocument()
    expect(screen.getByText("30")).toBeInTheDocument()
    expect(screen.getByText("41 viandas")).toBeInTheDocument()
    expect(screen.getByText("Gasto acumulado")).toBeInTheDocument()
    expect(screen.getByText(/6\.150/)).toBeInTheDocument()
    expect(screen.getByText(/Empleado: \$\s?4\.100/)).toBeInTheDocument()
  })

  it("desglosa el consumo por proveedor", () => {
    render(<AdminReports {...props} />)

    const section = within(
      screen.getByRole("region", { name: "Consumo por proveedor" }),
    )
    expect(section.getByText("Tu Viandita")).toBeInTheDocument()
    expect(section.getByText("28 viandas")).toBeInTheDocument()
    expect(section.getByText(/4\.200/)).toBeInTheDocument()
    expect(section.getByText("Endulzate by Noe")).toBeInTheDocument()
    expect(section.getByText("13 viandas")).toBeInTheDocument()
  })

  it("muestra ceros y el estado vacío sin actividad", () => {
    render(
      <AdminReports
        {...props}
        summary={{
          adhesion: 0,
          participants: 0,
          employees: 25,
          orders: 0,
          meals: 0,
          company_amount: 0,
          employee_amount: 0,
        }}
        providers={[]}
      />,
    )

    expect(screen.getByText("0%")).toBeInTheDocument()
    expect(screen.getByText("0 de 25 empleados")).toBeInTheDocument()
    expect(screen.getByText("0 viandas")).toBeInTheDocument()
    expect(screen.getByText("Sin consumos")).toBeInTheDocument()
    expect(
      screen.getByText("No hay pedidos confirmados en este período."),
    ).toBeInTheDocument()
    expect(screen.queryByText("Tu Viandita")).not.toBeInTheDocument()
  })

  it("navega al rango del preset", async () => {
    const user = userEvent.setup()
    render(<AdminReports {...props} />)

    await user.click(screen.getByRole("button", { name: "Período" }))
    await user.click(screen.getByRole("button", { name: "Mes pasado" }))

    expect(routerGet).toHaveBeenCalledExactlyOnceWith(
      "/rrhh/reportes?desde=2026-09-01&hasta=2026-09-30",
      {},
      { preserveScroll: true },
    )
  })

  it("vuelve a la ruta sin parámetros con el rango por defecto", async () => {
    const user = userEvent.setup()
    render(
      <AdminReports
        {...props}
        from="2026-09-01"
        to="2026-09-30"
        month_label="Septiembre 2026"
      />,
    )

    await user.click(screen.getByRole("button", { name: "Período" }))
    await user.click(screen.getByRole("button", { name: "Este mes" }))

    expect(routerGet).toHaveBeenCalledExactlyOnceWith(
      "/rrhh/reportes",
      {},
      { preserveScroll: true },
    )
  })
})
