import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import type React from "react"
import { afterEach, describe, expect, it, vi } from "vitest"

import { type OrderFilters, noFilters } from "@/lib/provider-orders"
import type { ProviderOrder } from "@/types"

import ProviderOrderDays from "./provider-order-days"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
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

const orders = [
  order({ id: 1, amount: 2, price: 600 }),
  order({
    id: 2,
    status: "confirmed",
    delivery_method: "home",
    price: 400,
    consumer_name: "Matías Rodríguez",
    menu_name: "Wok de verduras",
    address: "Av. Brasil 2584",
  }),
  order({
    id: 3,
    status: "cancelled",
    amount: 3,
    price: 1200,
    date: "2026-10-07",
    consumer_name: "Camila Herrera",
    menu_name: "Focaccia crispy",
  }),
]

function renderDays(
  props: Partial<React.ComponentProps<typeof ProviderOrderDays>> = {},
) {
  const filters: OrderFilters = props.filters ?? noFilters

  return render(
    <ProviderOrderDays
      orders={orders}
      today={TODAY}
      period="upcoming"
      {...props}
      filters={filters}
    />,
  )
}

const dayButton = (date: string) =>
  screen.getByRole("button", { name: new RegExp(`Día: ${date}`) })

afterEach(() => vi.restoreAllMocks())

describe("ProviderOrderDays", () => {
  it("abre hoy y resume sus viandas y su monto", () => {
    renderDays()

    const today = dayButton("06/10")

    expect(today).toHaveTextContent("Día: 06/10 | Viandas: 3 | Monto: $1.000")
    expect(today).toHaveAttribute("aria-expanded", "true")
    expect(screen.getByText("Bruno Pérez - GoGrow")).toBeInTheDocument()
    expect(
      screen.queryByText("Camila Herrera - GoGrow"),
    ).not.toBeInTheDocument()
    expect(dayButton("07/10")).toHaveAttribute("aria-expanded", "false")
  })

  it("muestra hoy aunque no tenga pedidos", () => {
    renderDays({ orders: [orders[2]] })

    expect(dayButton("06/10")).toHaveTextContent(
      "Día: 06/10 | Viandas: 0 | Monto: $0",
    )
    expect(screen.getByText("No hay pedidos")).toBeInTheDocument()
  })

  it("abre otro día al tocarlo y cierra el anterior", async () => {
    const user = userEvent.setup()
    renderDays()

    await user.click(dayButton("07/10"))

    expect(screen.getByText("Camila Herrera - GoGrow")).toBeInTheDocument()
    expect(screen.queryByText("Bruno Pérez - GoGrow")).not.toBeInTheDocument()
    expect(dayButton("06/10")).toHaveAttribute("aria-expanded", "false")
  })

  it("cierra el día abierto al tocarlo en una pantalla chica", async () => {
    const user = userEvent.setup()
    renderDays()

    await user.click(dayButton("06/10"))

    expect(dayButton("06/10")).toHaveAttribute("aria-expanded", "false")
  })

  it("no cierra el día elegido en una pantalla de escritorio", async () => {
    const user = userEvent.setup()
    vi.spyOn(window, "matchMedia").mockReturnValue({
      matches: true,
    } as MediaQueryList)
    renderDays()

    await user.click(dayButton("06/10"))

    expect(dayButton("06/10")).toHaveAttribute("aria-expanded", "true")
  })

  it("deja los botones visibles y habilita cada uno según el estado del pedido", () => {
    renderDays()

    const confirm = screen.getAllByRole("button", { name: "Confirmar" })
    const reject = screen.getAllByRole("button", { name: "Rechazar" })

    expect(confirm).toHaveLength(2)
    expect(confirm[0]).toBeEnabled()
    expect(reject[0]).toBeEnabled()
    expect(confirm[1]).toBeDisabled()
    expect(reject[1]).toBeEnabled()
  })

  it("muestra el estado y la modalidad de cada pedido", () => {
    renderDays()

    expect(screen.getByText("Por revisar")).toBeInTheDocument()
    expect(screen.getByText("Confirmado")).toBeInTheDocument()
    expect(
      screen.getByText("Enviar a: Av. 18 de Julio 1006 (Oficina)"),
    ).toBeInTheDocument()
    expect(
      screen.getByText("Enviar a: Av. Brasil 2584 (Casa)"),
    ).toBeInTheDocument()
  })

  it("filtra por estado y recalcula el resumen del día", () => {
    renderDays({ filters: { ...noFilters, status: "confirmed" } })

    expect(dayButton("06/10")).toHaveTextContent(
      "Día: 06/10 | Viandas: 1 | Monto: $400",
    )
    expect(screen.queryByText("Bruno Pérez - GoGrow")).not.toBeInTheDocument()
    expect(screen.getByText("Matías Rodríguez - GoGrow")).toBeInTheDocument()
    expect(
      screen.queryByRole("button", { name: /Día: 07\/10/ }),
    ).not.toBeInTheDocument()
  })

  it("filtra por tipo de entrega", () => {
    renderDays({ filters: { ...noFilters, delivery: "home" } })

    expect(screen.queryByText("Bruno Pérez - GoGrow")).not.toBeInTheDocument()
    expect(screen.getByText("Matías Rodríguez - GoGrow")).toBeInTheDocument()
  })

  it("busca por consumidor, plato o código sin distinguir acentos", () => {
    const { unmount } = renderDays({
      filters: { ...noFilters, search: "RODRIGUEZ" },
    })
    expect(screen.getByText("Matías Rodríguez - GoGrow")).toBeInTheDocument()
    expect(screen.queryByText("Bruno Pérez - GoGrow")).not.toBeInTheDocument()
    unmount()

    const { unmount: unmountCode } = renderDays({
      filters: { ...noFilters, search: "ped-1" },
    })
    expect(screen.getByText("Bruno Pérez - GoGrow")).toBeInTheDocument()
    unmountCode()

    renderDays({ filters: { ...noFilters, search: "wok" } })
    expect(screen.getByText("Matías Rodríguez - GoGrow")).toBeInTheDocument()
  })

  it("avisa cuando los filtros no encuentran nada", () => {
    renderDays({ filters: { ...noFilters, search: "zzz" } })

    expect(screen.getByText("No hay pedidos")).toBeInTheDocument()
    expect(
      screen.getByText("No tenés pedidos que coincidan con los filtros."),
    ).toBeInTheDocument()
  })

  describe("historial", () => {
    const past = [
      order({ id: 10, date: "2026-10-05", consumer_name: "Ana Gómez" }),
      order({ id: 11, date: "2026-10-03", consumer_name: "Luis Sosa" }),
    ]

    it("abre el día más reciente y no agrega hoy", () => {
      renderDays({ orders: past, period: "history" })

      expect(dayButton("05/10")).toHaveAttribute("aria-expanded", "true")
      expect(dayButton("03/10")).toHaveAttribute("aria-expanded", "false")
      expect(
        screen.queryByRole("button", { name: /Día: 06\/10/ }),
      ).not.toBeInTheDocument()
    })

    it("avisa cuando todavía no hay pedidos anteriores", () => {
      renderDays({ orders: [], period: "history" })

      expect(
        screen.getByText("Todavía no tenés pedidos anteriores."),
      ).toBeInTheDocument()
    })
  })
})
