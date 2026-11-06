import { act, render, screen, waitFor } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import type React from "react"
import { describe, expect, it, vi } from "vitest"

import type { ProviderOrder } from "@/types"

import Index from "./index"

const patchMock = vi.hoisted(() => vi.fn())

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Head: () => null,
    usePage: () => ({ props: { locale: "es" } }),
    router: { patch: patchMock },
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

vi.mock("@/layouts/app-layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="app-layout">{children}</div>
  ),
}))

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

const upcoming = [
  order({ id: 1 }),
  order({
    id: 2,
    status: "confirmed",
    delivery_method: "home",
    consumer_name: "Matías Rodríguez",
    menu_name: "Wok de verduras",
  }),
  order({
    id: 3,
    status: "cancelled",
    rejectable: false,
    consumer_name: "Camila Herrera",
    menu_name: "Focaccia crispy",
  }),
]

const past = [order({ id: 10, date: "2026-10-05", consumer_name: "Ana Gómez" })]

function renderPage() {
  return render(
    <Index today={TODAY} upcoming_orders={upcoming} past_orders={past} />,
  )
}

describe("Provider orders page", () => {
  it("muestra el título, los filtros y los pedidos de hoy", () => {
    renderPage()

    expect(screen.getByRole("heading", { name: "Pedidos" })).toBeInTheDocument()
    expect(screen.getByRole("tab", { name: "Próximos" })).toBeInTheDocument()
    expect(screen.getByRole("tab", { name: "Historial" })).toBeInTheDocument()
    expect(screen.getByRole("tab", { name: "Por revisar" })).toBeInTheDocument()
    expect(screen.getByRole("tab", { name: "Confirmados" })).toBeInTheDocument()
    expect(screen.getByRole("tab", { name: "Todos" })).toHaveAttribute(
      "aria-selected",
      "true",
    )
    expect(screen.getByText("Entregas:")).toBeInTheDocument()
    expect(
      screen.getByPlaceholderText("Buscar pedido, plato, consumidor..."),
    ).toBeInTheDocument()
    expect(screen.getByText("Bruno Pérez - GoGrow")).toBeInTheDocument()
    expect(screen.getByText("Camila Herrera - GoGrow")).toBeInTheDocument()
  })

  it("ofrece exportar los pedidos visibles sin parámetros por defecto", () => {
    renderPage()

    const link = screen.getByRole("link", { name: "Exportar pedidos" })

    expect(link).toHaveAttribute("href", "/proveedor/pedidos/exportar")
    expect(link).toHaveAttribute("download")
  })

  it("exporta con la pestaña, el estado, la entrega y la búsqueda aplicados", async () => {
    const user = userEvent.setup()
    render(
      <Index
        today={TODAY}
        upcoming_orders={upcoming}
        past_orders={[...past, order({ id: 11, date: "2026-10-05" })]}
      />,
    )

    await user.click(screen.getByRole("tab", { name: "Historial" }))
    await user.click(screen.getByRole("tab", { name: "Por revisar" }))
    await user.click(
      screen.getByRole("button", { name: "Filtrar por tipo de entrega" }),
    )
    await user.click(screen.getByLabelText("Oficina GoGrow"))
    await user.click(screen.getByRole("button", { name: "Aplicar" }))
    await user.type(
      screen.getByPlaceholderText("Buscar pedido, plato, consumidor..."),
      " ana gómez ",
    )

    const url = new URL(
      screen
        .getByRole("link", { name: "Exportar pedidos" })
        .getAttribute("href") ?? "",
      "http://localhost",
    )

    expect(url.pathname).toBe("/proveedor/pedidos/exportar")
    expect(Object.fromEntries(url.searchParams)).toEqual({
      periodo: "historial",
      estado: "pending",
      entrega: "office",
      busqueda: "ana gómez",
    })
  })

  it("no ofrece exportar cuando los filtros dejan la lista vacía", async () => {
    const user = userEvent.setup()
    renderPage()

    await user.type(
      screen.getByPlaceholderText("Buscar pedido, plato, consumidor..."),
      "zzz",
    )

    expect(
      screen.queryByRole("link", { name: "Exportar pedidos" }),
    ).not.toBeInTheDocument()
  })

  it("sin pedidos en el período muestra el estado vacío y no ofrece exportar", () => {
    render(<Index today={TODAY} upcoming_orders={[]} past_orders={past} />)

    expect(screen.getByText("No tenés pedidos")).toBeInTheDocument()
    expect(screen.queryByText("No hay pedidos")).not.toBeInTheDocument()
    expect(
      screen.queryByRole("link", { name: "Exportar pedidos" }),
    ).not.toBeInTheDocument()
  })

  it("oculta los filtros en mobile solo si el período no tiene pedidos", async () => {
    const user = userEvent.setup()
    render(<Index today={TODAY} upcoming_orders={[]} past_orders={past} />)
    const statusTabs = () =>
      screen
        .getByRole("tab", { name: "Por revisar" })
        .closest("[data-slot=tabs]")

    expect(statusTabs()).toHaveClass("max-lg:hidden")

    await user.click(screen.getByRole("tab", { name: "Historial" }))

    expect(statusTabs()).not.toHaveClass("max-lg:hidden")
  })

  it("deja los filtros a la vista cuando son ellos los que vacían la lista", async () => {
    const user = userEvent.setup()
    renderPage()

    await user.type(
      screen.getByPlaceholderText("Buscar pedido, plato, consumidor..."),
      "zzz",
    )

    expect(
      screen.getByText("No tenés pedidos que coincidan con los filtros."),
    ).toBeInTheDocument()
    expect(
      screen
        .getByRole("tab", { name: "Por revisar" })
        .closest("[data-slot=tabs]"),
    ).not.toHaveClass("max-lg:hidden")
  })

  it("muestra solo los pedidos por revisar", async () => {
    const user = userEvent.setup()
    renderPage()

    await user.click(screen.getByRole("tab", { name: "Por revisar" }))

    expect(screen.getByText("Bruno Pérez - GoGrow")).toBeInTheDocument()
    expect(
      screen.queryByText("Matías Rodríguez - GoGrow"),
    ).not.toBeInTheDocument()
    expect(
      screen.queryByText("Camila Herrera - GoGrow"),
    ).not.toBeInTheDocument()
  })

  it("cambia al historial", async () => {
    const user = userEvent.setup()
    renderPage()

    await user.click(screen.getByRole("tab", { name: "Historial" }))

    expect(screen.getByText("Ana Gómez - GoGrow")).toBeInTheDocument()
    expect(screen.queryByText("Bruno Pérez - GoGrow")).not.toBeInTheDocument()
  })

  it("no muestra acciones para un pedido confirmado pasado en el historial", async () => {
    const user = userEvent.setup()
    render(
      <Index
        today={TODAY}
        upcoming_orders={upcoming}
        past_orders={[
          order({
            id: 99,
            status: "confirmed",
            rejectable: false,
            date: "2026-10-05",
            consumer_name: "Ana Gómez",
          }),
        ]}
      />,
    )

    await user.click(screen.getByRole("tab", { name: "Historial" }))

    expect(screen.getByText("Ana Gómez - GoGrow")).toBeInTheDocument()
    expect(
      screen.queryByRole("button", { name: "Rechazar" }),
    ).not.toBeInTheDocument()
    expect(
      screen.queryByRole("button", { name: "Confirmar" }),
    ).not.toBeInTheDocument()
  })

  it("mantiene los filtros al cambiar de pestaña", async () => {
    const user = userEvent.setup()
    renderPage()

    await user.type(
      screen.getByPlaceholderText("Buscar pedido, plato, consumidor..."),
      "zzz",
    )
    await user.click(screen.getByRole("tab", { name: "Historial" }))

    expect(
      screen.getByText("No tenés pedidos que coincidan con los filtros."),
    ).toBeInTheDocument()
    expect(
      screen.getByPlaceholderText("Buscar pedido, plato, consumidor..."),
    ).toHaveValue("zzz")
  })

  describe("al decidir un pedido que sale de la lista filtrada", () => {
    function finishDecision() {
      const options = patchMock.mock.lastCall?.[2] as {
        onSuccess: (page: unknown) => void
        onFinish: () => void
      }

      act(() => {
        options.onSuccess({ props: {} })
        options.onFinish()
      })
    }

    it("mantiene la hoja de confirmado aunque la tarjeta desaparezca de Por revisar", async () => {
      const user = userEvent.setup()
      const pending = order({ id: 1 })
      const { rerender } = render(
        <Index today={TODAY} upcoming_orders={[pending]} past_orders={past} />,
      )

      await user.click(screen.getByRole("tab", { name: "Por revisar" }))
      await user.click(screen.getByRole("button", { name: "Confirmar" }))
      rerender(
        <Index
          today={TODAY}
          upcoming_orders={[{ ...pending, status: "confirmed" }]}
          past_orders={past}
        />,
      )
      finishDecision()

      expect(screen.queryByText("Bruno Pérez - GoGrow")).not.toBeInTheDocument()
      expect(screen.getByText("Pedido confirmado")).toBeInTheDocument()
      expect(
        screen.getByText(
          "El pedido #1 quedó confirmado y Bruno Pérez recibirá una notificación.",
        ),
      ).toBeInTheDocument()

      await user.click(screen.getByRole("button", { name: "Listo" }))
      await waitFor(() =>
        expect(screen.queryByRole("dialog")).not.toBeInTheDocument(),
      )
    })

    it("mantiene la hoja de rechazado aunque la tarjeta desaparezca de Confirmados", async () => {
      const user = userEvent.setup()
      const confirmed = order({ id: 2, status: "confirmed" })
      const { rerender } = render(
        <Index
          today={TODAY}
          upcoming_orders={[confirmed]}
          past_orders={past}
        />,
      )

      await user.click(screen.getByRole("tab", { name: "Confirmados" }))
      await user.click(screen.getByRole("button", { name: "Rechazar" }))
      await user.click(screen.getByLabelText("Sin stock disponible"))
      await user.click(screen.getByRole("button", { name: "Rechazar pedido" }))
      rerender(
        <Index
          today={TODAY}
          upcoming_orders={[
            { ...confirmed, status: "rejected", rejectable: false },
          ]}
          past_orders={past}
        />,
      )
      finishDecision()

      expect(screen.queryByText("Bruno Pérez - GoGrow")).not.toBeInTheDocument()
      expect(screen.getByText("Pedido rechazado")).toBeInTheDocument()
    })
  })

  it("busca entre los pedidos", async () => {
    const user = userEvent.setup()
    renderPage()

    await user.type(
      screen.getByPlaceholderText("Buscar pedido, plato, consumidor..."),
      "wok",
    )

    expect(screen.getByText("Matías Rodríguez - GoGrow")).toBeInTheDocument()
    expect(screen.queryByText("Bruno Pérez - GoGrow")).not.toBeInTheDocument()
  })

  it("filtra por tipo de entrega desde el sheet", async () => {
    const user = userEvent.setup()
    renderPage()

    await user.click(
      screen.getByRole("button", { name: "Filtrar por tipo de entrega" }),
    )
    await user.click(screen.getByLabelText("Domicilios"))
    await user.click(screen.getByRole("button", { name: "Aplicar" }))

    expect(screen.getByText("Domicilios")).toBeInTheDocument()
    expect(screen.getByText("Matías Rodríguez - GoGrow")).toBeInTheDocument()
    expect(screen.queryByText("Bruno Pérez - GoGrow")).not.toBeInTheDocument()
  })
})
