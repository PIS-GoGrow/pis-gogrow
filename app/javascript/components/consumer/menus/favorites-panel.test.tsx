import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { beforeEach, describe, expect, it, vi } from "vitest"

import { toggleFavorite } from "@/lib/favorites"
import type { ConsumerDashboardIndex } from "@/types"

import FavoritesPanel from "./favorites-panel"

vi.mock("@/lib/favorites", () => ({ toggleFavorite: vi.fn() }))

type Schedule = ConsumerDashboardIndex["schedules"][number]

const providers: ConsumerDashboardIndex["providers"] = [
  { id: 1, name: "La Cocina", order_deadline: null },
  { id: 2, name: "Otro proveedor", order_deadline: null },
]

const dish = (id: number, name: string, providerId = 1) => ({
  id,
  name,
  description: null,
  price: 300,
  provider_id: providerId,
  provider_name: providers[providerId - 1].name,
})

const schedule = (
  savedMenuId: number,
  overrides: Partial<Schedule> = {},
): Schedule => ({
  id: savedMenuId * 100,
  date: "2026-10-26",
  remaining: 5,
  sold_out: false,
  orders_closed: false,
  menu: {
    ...dish(savedMenuId, "Plato"),
    saved_menu_id: savedMenuId,
    option_groups: [],
    home_delivery: true,
    rating_average: null,
    rating_count: 0,
    reviews: [],
  },
  ...overrides,
})

function renderPanel(
  props: Partial<React.ComponentProps<typeof FavoritesPanel>> = {},
) {
  const openDetail = vi.fn()
  const setActiveProviders = vi.fn()

  render(
    <FavoritesPanel
      favorites={{ menus: [], provider_ids: [] }}
      frequent={{ menus: [], provider_ids: [] }}
      providers={providers}
      schedules={[]}
      activeProviders={new Set()}
      setActiveProviders={setActiveProviders}
      openDetail={openDetail}
      {...props}
    />,
  )

  return { openDetail, setActiveProviders }
}

describe("FavoritesPanel", () => {
  beforeEach(() => vi.clearAllMocks())

  it("no se muestra sin favoritos ni frecuentes", () => {
    renderPanel()

    expect(screen.queryByRole("heading")).not.toBeInTheDocument()
  })

  it("separa los favoritos elegidos de los frecuentes calculados", () => {
    renderPanel({
      favorites: { menus: [dish(1, "Milanesa")], provider_ids: [] },
      frequent: { menus: [dish(2, "Sorrentinos")], provider_ids: [] },
    })

    expect(screen.getByText("Tus favoritos")).toBeInTheDocument()
    expect(screen.getByText("Los que pedís seguido")).toBeInTheDocument()
    expect(screen.getByText("Favorito")).toBeInTheDocument()
    expect(screen.getByText("Frecuente")).toBeInTheDocument()
  })

  it("no repite como frecuente lo que ya es favorito", () => {
    renderPanel({
      favorites: { menus: [dish(1, "Milanesa")], provider_ids: [] },
      frequent: { menus: [dish(1, "Milanesa")], provider_ids: [] },
    })

    expect(screen.getAllByText(/Milanesa/)).toHaveLength(1)
    expect(screen.queryByText("Los que pedís seguido")).not.toBeInTheDocument()
  })

  it("abre el detalle de un plato disponible", async () => {
    const available = schedule(1)
    const { openDetail } = renderPanel({
      favorites: { menus: [dish(1, "Milanesa")], provider_ids: [] },
      schedules: [available],
    })

    await userEvent.click(screen.getByText(/Milanesa/))

    expect(openDetail).toHaveBeenCalledWith(available)
  })

  it.each([
    ["sin programación ese día", []],
    ["agotado", [schedule(1, { sold_out: true })]],
    ["con pedidos cerrados", [schedule(1, { orders_closed: true })]],
  ])(
    "muestra como referencia un plato %s y no deja pedirlo",
    async (_, schedules) => {
      const { openDetail } = renderPanel({
        favorites: { menus: [dish(1, "Milanesa")], provider_ids: [] },
        schedules,
      })

      expect(screen.getByText("No disponible este día")).toBeInTheDocument()
      await userEvent.click(screen.getByText(/Milanesa/))
      expect(openDetail).not.toHaveBeenCalled()
    },
  )

  it("marca y desmarca favoritos", async () => {
    renderPanel({
      favorites: { menus: [dish(1, "Milanesa")], provider_ids: [] },
      frequent: { menus: [dish(2, "Sorrentinos")], provider_ids: [2] },
    })

    await userEvent.click(
      screen.getByRole("button", { name: "Quitar Milanesa de favoritos" }),
    )
    await userEvent.click(
      screen.getByRole("button", { name: "Marcar Sorrentinos como favorito" }),
    )
    await userEvent.click(
      screen.getByRole("button", {
        name: "Marcar Otro proveedor como favorito",
      }),
    )

    expect(toggleFavorite).toHaveBeenNthCalledWith(1, "menus", 1, true)
    expect(toggleFavorite).toHaveBeenNthCalledWith(2, "menus", 2, false)
    expect(toggleFavorite).toHaveBeenNthCalledWith(3, "providers", 2, false)
  })

  it("filtra por un proveedor favorito", async () => {
    const { setActiveProviders } = renderPanel({
      favorites: { menus: [], provider_ids: [1] },
    })

    await userEvent.click(
      screen.getByRole("button", { name: "Ver platos de La Cocina" }),
    )

    expect(setActiveProviders).toHaveBeenCalledWith(new Set([1]))
  })
})
