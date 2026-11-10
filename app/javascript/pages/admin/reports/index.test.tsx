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
    daily_consumption: [
      { date: "2026-10-10", orders: 20, meals: 28, company_amount: 4200 },
      { date: "2026-10-15", orders: 10, meals: 13, company_amount: 1950 },
    ],
    delivery_methods: {
      office: { orders: 25, meals: 35 },
      home: { orders: 5, meals: 6 },
    },
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

  it("muestra adhesión 0% y 0 de 0 empleados si la empresa no tiene empleados registrados", () => {
    render(
      <AdminReports
        {...props}
        summary={{
          adhesion: 0,
          participants: 0,
          employees: 0,
          orders: 0,
          meals: 0,
          company_amount: 0,
          employee_amount: 0,
        }}
        providers={[]}
      />,
    )

    expect(screen.getByText("0%")).toBeInTheDocument()
    expect(screen.getByText("0 de 0 empleados")).toBeInTheDocument()
  })

  it("formatea correctamente cifras con decimales", () => {
    render(
      <AdminReports
        {...props}
        summary={{
          ...props.summary,
          company_amount: 440.25,
          employee_amount: 150.75,
        }}
      />,
    )

    expect(screen.getByText(/440,25/)).toBeInTheDocument()
    expect(screen.getByText(/Empleado: \$\s?150,75/)).toBeInTheDocument()
  })

  it("muestra la distribución del gasto, modalidad de entrega y actividad diaria", () => {
    render(
      <AdminReports
        {...props}
        daily_consumption={[
          { date: "2026-10-10", orders: 2, meals: 3, company_amount: 450 },
          { date: "2026-10-15", orders: 1, meals: 2, company_amount: 300 },
        ]}
        delivery_methods={{
          office: { orders: 25, meals: 35 },
          home: { orders: 5, meals: 6 },
        }}
      />,
    )

    expect(screen.getByText("Distribución del gasto")).toBeInTheDocument()
    expect(screen.getByText("Modalidad de entrega")).toBeInTheDocument()
    expect(screen.getByText("Evolución en el período")).toBeInTheDocument()
    expect(screen.getByText("En oficina")).toBeInTheDocument()
    expect(screen.getByText("A domicilio")).toBeInTheDocument()
    expect(screen.getByText("35")).toBeInTheDocument()
    expect(screen.getByText("6")).toBeInTheDocument()
    expect(screen.getByText("10/10")).toBeInTheDocument()
    expect(screen.getByText("15/10")).toBeInTheDocument()
  })

  it("muestra coherentemente todas las estadísticas en un escenario de alto volumen de datos", () => {
    // 31 días de consumo diario con altos volúmenes
    const highVolumeDays = Array.from({ length: 31 }, (_, i) => {
      const day = String(i + 1).padStart(2, "0")
      return {
        date: `2026-10-${day}`,
        orders: 150 + (i % 5) * 10,
        meals: 200 + (i % 5) * 15,
        company_amount: 30000 + i * 1000,
      }
    })

    const totalDaysOrders = highVolumeDays.reduce((acc, d) => acc + d.orders, 0)
    const totalDaysMeals = highVolumeDays.reduce((acc, d) => acc + d.meals, 0)
    const totalDaysCompanyAmount = highVolumeDays.reduce(
      (acc, d) => acc + d.company_amount,
      0,
    )

    const highVolumeProviders = [
      {
        id: 1,
        name: "Tu Viandita",
        orders: 2000,
        meals: Math.round(totalDaysMeals * 0.45),
        company_amount: Math.round(totalDaysCompanyAmount * 0.45),
      },
      {
        id: 2,
        name: "Endulzate",
        orders: 1500,
        meals: Math.round(totalDaysMeals * 0.3),
        company_amount: Math.round(totalDaysCompanyAmount * 0.3),
      },
      {
        id: 3,
        name: "Chef Express",
        orders: 1000,
        meals: Math.round(totalDaysMeals * 0.15),
        company_amount: Math.round(totalDaysCompanyAmount * 0.15),
      },
      {
        id: 4,
        name: "Gourmet Saludable",
        orders: 500,
        meals:
          totalDaysMeals -
          Math.round(totalDaysMeals * 0.45) -
          Math.round(totalDaysMeals * 0.3) -
          Math.round(totalDaysMeals * 0.15),
        company_amount:
          totalDaysCompanyAmount -
          Math.round(totalDaysCompanyAmount * 0.45) -
          Math.round(totalDaysCompanyAmount * 0.3) -
          Math.round(totalDaysCompanyAmount * 0.15),
      },
    ]

    const officeOrders = Math.round(totalDaysOrders * 0.7)
    const homeOrders = totalDaysOrders - officeOrders
    const officeMeals = Math.round(totalDaysMeals * 0.7)
    const homeMeals = totalDaysMeals - officeMeals

    const highVolumeProps = {
      ...props,
      summary: {
        adhesion: 88,
        participants: 440,
        employees: 500,
        orders: totalDaysOrders,
        meals: totalDaysMeals,
        company_amount: totalDaysCompanyAmount,
        employee_amount: 450000,
      },
      providers: highVolumeProviders,
      daily_consumption: highVolumeDays,
      delivery_methods: {
        office: { orders: officeOrders, meals: officeMeals },
        home: { orders: homeOrders, meals: homeMeals },
      },
    }

    render(<AdminReports {...highVolumeProps} />)

    // 1. Verificación de los indicadores clave
    expect(screen.getByText("88%")).toBeInTheDocument()
    expect(screen.getByText("440 de 500 empleados")).toBeInTheDocument()
    expect(screen.getByText(String(totalDaysOrders))).toBeInTheDocument()
    expect(screen.getByText(`${totalDaysMeals} viandas`)).toBeInTheDocument()

    // 2. Gráfico de evolución diaria: todos los 31 días presentes sin excepciones
    for (let i = 1; i <= 31; i++) {
      const dayStr = String(i).padStart(2, "0")
      expect(screen.getByText(`${dayStr}/10`)).toBeInTheDocument()
    }

    // 3. Verificación de que no existen NaN ni undefined en las barras o elementos de la pantalla
    const allProgressBars = document.querySelectorAll(
      "[style*='width'], [style*='height']",
    )
    expect(allProgressBars.length).toBeGreaterThan(0)
    allProgressBars.forEach((bar) => {
      const style = bar.getAttribute("style") ?? ""
      expect(style).not.toContain("NaN")
      expect(style).not.toContain("undefined")
    })

    // 4. Modalidades de entrega: cantidades y porcentajes
    expect(screen.getByText(String(officeMeals))).toBeInTheDocument()
    expect(screen.getByText(String(homeMeals))).toBeInTheDocument()
    expect(screen.getByText(/En oficina: 70%/)).toBeInTheDocument()
    expect(screen.getByText(/A domicilio: 30%/)).toBeInTheDocument()

    // 5. Proveedores: todos los 4 proveedores listados
    expect(screen.getByText("Tu Viandita")).toBeInTheDocument()
    expect(screen.getByText("Endulzate")).toBeInTheDocument()
    expect(screen.getByText("Chef Express")).toBeInTheDocument()
    expect(screen.getByText("Gourmet Saludable")).toBeInTheDocument()
  })
})
