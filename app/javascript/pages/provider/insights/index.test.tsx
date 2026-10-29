import { render, screen, within } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import type React from "react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import ProviderInsights from "./index"

const { routerGet } = vi.hoisted(() => ({ routerGet: vi.fn() }))

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Head: () => null,
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

describe("Provider Insights Page", () => {
  const defaultProps = {
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
    orders_count: 84,
    dishes_count: 15,
    average_rating: 4.7,
    top_dishes: [
      { id: 1, name: "Milanesa con Puré", orders_count: 24 },
      { id: 2, name: "Wok de Verduras", orders_count: 18 },
    ],
    top_rated_dishes: [
      { id: 2, name: "Wok de Verduras", rating: 5 },
      { id: 3, name: "Lasaña veggie", rating: 4.9 },
    ],
  }

  it("muestra el título, el volver al Inicio y el período elegido", () => {
    render(<ProviderInsights {...defaultProps} />)

    expect(
      screen.getByRole("heading", { name: "Hallazgos" }),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("link", { name: "Volver al inicio" }),
    ).toHaveAttribute("href", "/proveedor/inicio")
    expect(screen.getByRole("button", { name: "Período" })).toHaveTextContent(
      "Octubre 2026",
    )
  })

  it("muestra las métricas del período y la tarjeta generada por IA", () => {
    render(<ProviderInsights {...defaultProps} />)

    expect(screen.getByText("84")).toBeInTheDocument()
    expect(screen.getByText("Pedidos")).toBeInTheDocument()
    expect(screen.getByText("15")).toBeInTheDocument()
    expect(screen.getByText("Platos")).toBeInTheDocument()
    expect(screen.getByText("4.7")).toBeInTheDocument()
    expect(screen.getByText("Valoración")).toBeInTheDocument()
    expect(screen.getByText("Generado por IA")).toBeInTheDocument()
  })

  it("lista los platos más pedidos y los mejor valorados", () => {
    render(<ProviderInsights {...defaultProps} />)

    const topDishes = screen.getByRole("region", {
      name: "Platos más pedidos",
    })
    const rows = within(topDishes).getAllByRole("listitem")
    expect(rows.map((row) => row.textContent)).toEqual([
      "Milanesa con Puréx24",
      "Wok de Verdurasx18",
    ])

    const topRated = screen.getByRole("region", { name: "Mejor valorados" })
    expect(
      within(topRated)
        .getAllByRole("listitem")
        .map((row) => row.textContent),
    ).toEqual(["Wok de Verduras5", "Lasaña veggie4.9"])
  })

  it("muestra ceros, un guión y los estados vacíos sin actividad", () => {
    render(
      <ProviderInsights
        {...defaultProps}
        orders_count={0}
        dishes_count={0}
        average_rating={undefined}
        top_dishes={[]}
        top_rated_dishes={[]}
      />,
    )

    expect(screen.getAllByText("0")).toHaveLength(2)
    expect(screen.getByText("—")).toBeInTheDocument()
    expect(
      screen.getByText("Todavía no hay pedidos en este período"),
    ).toBeInTheDocument()
    expect(
      screen.getByText("Todavía no hay reseñas en este período"),
    ).toBeInTheDocument()
    expect(screen.queryByRole("listitem")).not.toBeInTheDocument()
  })

  it("muestra un rango custom con el formato de rango", () => {
    render(
      <ProviderInsights
        {...defaultProps}
        from="2026-08-02"
        to="2026-09-04"
        month_label={undefined}
      />,
    )

    expect(screen.getByRole("button", { name: "Período" })).toHaveTextContent(
      "02/08/26 – 04/09/26",
    )
  })

  it("ofrece los presets en orden y navega al rango del preset", async () => {
    const user = userEvent.setup()
    render(<ProviderInsights {...defaultProps} />)

    await user.click(screen.getByRole("button", { name: "Período" }))
    const presets = ["Hoy", "Ayer", "Esta semana", "Este mes", "Mes pasado"]
    for (const label of presets) {
      expect(screen.getByRole("button", { name: label })).toBeInTheDocument()
    }
    await user.click(screen.getByRole("button", { name: "Mes pasado" }))

    expect(routerGet).toHaveBeenCalledExactlyOnceWith(
      "/proveedor/inicio/hallazgos?desde=2026-09-01&hasta=2026-09-30",
      {},
      { preserveScroll: true },
    )
    expect(
      screen.queryByRole("button", { name: "Hoy" }),
    ).not.toBeInTheDocument()
  })

  it("vuelve a la ruta sin parámetros con el rango por defecto", async () => {
    const user = userEvent.setup()
    render(
      <ProviderInsights
        {...defaultProps}
        from="2026-09-01"
        to="2026-09-30"
        month_label="Septiembre 2026"
      />,
    )

    await user.click(screen.getByRole("button", { name: "Período" }))
    await user.click(screen.getByRole("button", { name: "Este mes" }))

    expect(routerGet).toHaveBeenCalledExactlyOnceWith(
      "/proveedor/inicio/hallazgos",
      {},
      { preserveScroll: true },
    )
  })

  it("navega una sola vez, recién al elegir el inicio y el fin del rango", async () => {
    const user = userEvent.setup()
    render(<ProviderInsights {...defaultProps} />)

    await user.click(screen.getByRole("button", { name: "Período" }))
    await user.click(screen.getByRole("button", { name: /, 12 de octubre/ }))
    expect(routerGet).not.toHaveBeenCalled()
    await user.click(screen.getByRole("button", { name: /, 5 de octubre/ }))

    expect(routerGet).toHaveBeenCalledExactlyOnceWith(
      "/proveedor/inicio/hallazgos?desde=2026-10-05&hasta=2026-10-12",
      {},
      { preserveScroll: true },
    )
  })

  it("toma el inicio como rango de un día si se cierra el calendario sin el fin", async () => {
    const user = userEvent.setup()
    render(<ProviderInsights {...defaultProps} />)

    await user.click(screen.getByRole("button", { name: "Período" }))
    await user.click(screen.getByRole("button", { name: /, 12 de octubre/ }))
    await user.keyboard("{Escape}")

    expect(routerGet).toHaveBeenCalledExactlyOnceWith(
      "/proveedor/inicio/hallazgos?desde=2026-10-12&hasta=2026-10-12",
      {},
      { preserveScroll: true },
    )
  })
})
