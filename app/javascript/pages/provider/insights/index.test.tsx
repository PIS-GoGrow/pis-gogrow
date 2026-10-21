import { render, screen, within } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import type React from "react"
import { beforeAll, beforeEach, describe, expect, it, vi } from "vitest"

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

// El Select de Radix usa APIs de puntero y de scroll que jsdom no trae.
beforeAll(() => {
  Element.prototype.hasPointerCapture = () => false
  Element.prototype.releasePointerCapture = () => undefined
  Element.prototype.scrollIntoView = () => undefined
})

beforeEach(() => routerGet.mockClear())

describe("Provider Insights Page", () => {
  const defaultProps = {
    period: "2026-09",
    current_period: "2026-10",
    periods: [
      { key: "2026-10", label: "Octubre 2026" },
      { key: "2026-09", label: "Septiembre 2026" },
      { key: "2026-08", label: "Agosto 2026" },
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
    expect(screen.getByRole("combobox", { name: "Período" })).toHaveTextContent(
      "Septiembre 2026",
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

  it("navega al período elegido conservando el scroll", async () => {
    const user = userEvent.setup()
    render(<ProviderInsights {...defaultProps} />)

    await user.click(screen.getByRole("combobox", { name: "Período" }))
    await user.click(screen.getByRole("option", { name: "Agosto 2026" }))

    expect(routerGet).toHaveBeenCalledWith(
      "/proveedor/hallazgos?period=2026-08",
      {},
      { preserveScroll: true },
    )
  })

  it("vuelve a la ruta sin parámetro al elegir el mes actual", async () => {
    const user = userEvent.setup()
    render(<ProviderInsights {...defaultProps} />)

    await user.click(screen.getByRole("combobox", { name: "Período" }))
    await user.click(screen.getByRole("option", { name: "Octubre 2026" }))

    expect(routerGet).toHaveBeenCalledWith(
      "/proveedor/hallazgos",
      {},
      { preserveScroll: true },
    )
  })
})
