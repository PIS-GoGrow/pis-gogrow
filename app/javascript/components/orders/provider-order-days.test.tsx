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
    rejectable: true,
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
    rejectable: false,
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
      onDecided={vi.fn()}
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

  it("no agrega hoy si no tiene pedidos y abre el primer día con pedidos", () => {
    renderDays({ orders: [orders[2]] })

    expect(
      screen.queryByRole("button", { name: /Día: 06\/10/ }),
    ).not.toBeInTheDocument()
    expect(dayButton("07/10")).toHaveAttribute("aria-expanded", "true")
    expect(screen.queryByText("No hay pedidos")).not.toBeInTheDocument()
    expect(screen.queryByText("No tenés pedidos")).not.toBeInTheDocument()
  })

  it("muestra el estado vacío del diseño sin ningún día si no hay pedidos", () => {
    renderDays({ orders: [] })

    expect(
      screen.queryByRole("button", { name: /Día:/ }),
    ).not.toBeInTheDocument()
    expect(screen.queryByText("No hay pedidos")).not.toBeInTheDocument()
    expect(screen.getByText("No tenés pedidos")).toBeInTheDocument()
    expect(
      screen.getByText(
        "Cuando tus clientes hagan pedidos, van a aparecer acá.",
      ),
    ).toBeInTheDocument()
  })

  it("avisa que no hay pedidos al filtrar pendientes sin ninguno", () => {
    renderDays({ orders: [], filters: { ...noFilters, status: "pending" } })

    expect(screen.getByText("No tenés pedidos")).toBeInTheDocument()
    expect(
      screen.getByText(
        "Cuando tus clientes hagan pedidos, van a aparecer acá.",
      ),
    ).toBeInTheDocument()
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

  it("muestra en cada tarjeta solo las acciones disponibles", () => {
    renderDays()

    expect(screen.getAllByRole("button", { name: "Confirmar" })).toHaveLength(1)
    expect(screen.getAllByRole("button", { name: "Rechazar" })).toHaveLength(2)
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

  it.each([
    ["una búsqueda", { orders, filters: { ...noFilters, search: "zzz" } }],
    [
      "la pestaña de estado",
      { orders: [orders[0]], filters: { ...noFilters, status: "confirmed" } },
    ],
    [
      "un período sin pedidos con filtros",
      { orders: [], filters: { ...noFilters, search: "zzz" } },
    ],
  ] as const)("usa los textos del diseño con %s sin resultados", (_, props) => {
    renderDays({ ...props, orders: [...props.orders] })

    expect(screen.getByText("No tenés pedidos")).toBeInTheDocument()
    expect(
      screen.getByText(
        "Cuando tus clientes hagan pedidos, van a aparecer acá.",
      ),
    ).toBeInTheDocument()
    expect(screen.queryByText("No hay pedidos")).not.toBeInTheDocument()
    expect(screen.queryByText(/coincidan/)).not.toBeInTheDocument()
  })

  describe("historial", () => {
    const past = [
      order({ id: 10, date: "2026-10-05", consumer_name: "Ana Gómez" }),
      order({ id: 11, date: "2026-10-03", consumer_name: "Luis Sosa" }),
    ]

    it("abre el día más reciente y no agrega hoy", () => {
      renderDays({ orders: past })

      expect(dayButton("05/10")).toHaveAttribute("aria-expanded", "true")
      expect(dayButton("03/10")).toHaveAttribute("aria-expanded", "false")
      expect(
        screen.queryByRole("button", { name: /Día: 06\/10/ }),
      ).not.toBeInTheDocument()
    })

    it("avisa cuando todavía no hay pedidos anteriores", () => {
      renderDays({ orders: [] })

      expect(screen.getByText("No tenés pedidos")).toBeInTheDocument()
    })
  })
})
