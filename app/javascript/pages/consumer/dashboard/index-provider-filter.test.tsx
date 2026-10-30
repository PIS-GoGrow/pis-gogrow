import {
  act,
  render as testingRender,
  screen,
  waitFor,
} from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import type { ComponentProps, ReactNode } from "react"
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest"

import { ConsumerMenuFilterProvider } from "@/hooks/consumer-menu-filter"
import { consumerCartStorageKey } from "@/hooks/use-consumer-cart"
import type { ConsumerDashboardIndex } from "@/types"

import type { CartItem } from "./consumer-types"
import { priceItems } from "./pricing"

import Index from "./index"

function render(ui: ReactNode) {
  return testingRender(ui, { wrapper: ConsumerMenuFilterProvider })
}

vi.mock("@/layouts/app-layout", () => ({
  default: ({ children }: { children: ReactNode }) => children,
}))

vi.mock("@inertiajs/react", async () => ({
  ...(await vi.importActual("@inertiajs/react")),
  Head: () => null,
  usePage: () => ({
    url: "/menu-semanal",
    props: {
      auth: {
        user: { name: "Sofía" },
        session: { id: 10, role: "consumer" },
      },
      notifications: [],
    },
  }),
  Link: ({ children, ...props }: ComponentProps<"a">) => (
    <a {...props}>{children}</a>
  ),
}))

vi.mock("./pricing", async () => ({
  ...(await vi.importActual("./pricing")),
  priceItems: vi.fn(),
}))

const providers: ConsumerDashboardIndex["providers"] = [
  { id: 1, name: "La Cocina", order_deadline: null },
  { id: 2, name: "Otro proveedor", order_deadline: null },
  { id: 3, name: "La Cocina", order_deadline: null },
]

const schedules: ConsumerDashboardIndex["schedules"] = [26, 27].flatMap((day) =>
  providers.map((provider) => ({
    id: day * 10 + provider.id,
    date: `2026-10-${day}`,
    remaining: 10,
    sold_out: false,
    orders_closed: false,
    menu: {
      id: provider.id,
      name: `Plato ${provider.id} día ${day}`,
      description: null,
      price: 300,
      provider_id: provider.id,
      saved_menu_id: provider.id,
      provider_name: provider.name,
      option_groups: [],
      home_delivery: true,
      rating_average: null,
      rating_count: 0,
      reviews: [],
    },
  })),
)

const props: ConsumerDashboardIndex = {
  providers,
  schedules,
  closures: [],
  favorites: { menus: [], provider_ids: [] },
  frequent: { menus: [], provider_ids: [] },
  week: {
    start_date: "2026-10-26",
    end_date: "2026-10-30",
    days: [26, 27].map((day) => ({
      date: `2026-10-${day}`,
      weekday: day === 26 ? "lunes" : "martes",
      day,
    })),
  },
  benefit: {
    percentage: 50,
    monthly_limit: 20,
    monthly_used: 0,
    monthly_remaining: 20,
    specials: [],
  },
}

const cartStorageKey = consumerCartStorageKey({ id: 10, role: "consumer" })

async function applyFilter(user: ReturnType<typeof userEvent.setup>) {
  await user.click(
    screen.getByRole("button", { name: "Filtrar por proveedores" }),
  )
  await user.click(screen.getAllByLabelText("La Cocina")[1])
  await user.click(screen.getByRole("button", { name: "Aplicar" }))
}

function expectFilteredDay(day: number) {
  expect(screen.getByText(`Plato 1 día ${day}`)).toBeInTheDocument()
  expect(screen.getByText(`Plato 2 día ${day}`)).toBeInTheDocument()
  expect(screen.queryByText(`Plato 3 día ${day}`)).not.toBeInTheDocument()
}

beforeEach(() => {
  vi.useFakeTimers({ toFake: ["Date"] })
  vi.setSystemTime(new Date(2026, 9, 26, 12))
  window.sessionStorage.clear()
  vi.clearAllMocks()
  vi.mocked(priceItems).mockImplementation((items) => {
    const quantity = items.reduce((sum, item) => sum + item.quantity, 0)
    return Promise.resolve({
      subtotal: quantity * 300,
      discount: quantity * 150,
      total: quantity * 150,
      lines: [],
      subsidizedQuantity: quantity,
      fullPriceQuantity: 0,
    })
  })
})

afterEach(() => {
  vi.useRealTimers()
})

describe("Consumer menu provider filter navigation", () => {
  it("keeps applied IDs when the menu unmounts for payments, and clears on a new session", async () => {
    const user = userEvent.setup()
    const { rerender } = testingRender(
      <ConsumerMenuFilterProvider key="session-1">
        <Index {...props} />
      </ConsumerMenuFilterProvider>,
    )
    await applyFilter(user)
    expectFilteredDay(26)
    rerender(
      <ConsumerMenuFilterProvider key="session-1">
        <div>Pagos</div>
      </ConsumerMenuFilterProvider>,
    )
    expect(screen.getByText("Pagos")).toBeInTheDocument()
    rerender(
      <ConsumerMenuFilterProvider key="session-1">
        <Index {...props} />
      </ConsumerMenuFilterProvider>,
    )
    expectFilteredDay(26)
    rerender(
      <ConsumerMenuFilterProvider key="guest">
        <div>Ingresar</div>
      </ConsumerMenuFilterProvider>,
    )
    rerender(
      <ConsumerMenuFilterProvider key="session-2">
        <Index {...props} />
      </ConsumerMenuFilterProvider>,
    )
    expect(screen.getByText(`Plato 3 d\u00eda 26`)).toBeInTheDocument()
  })

  it("preserves reviews and provider selection through dish detail without changing the cart", async () => {
    const user = userEvent.setup()
    const reviewedSchedule = {
      ...schedules[0],
      menu: {
        ...schedules[0].menu,
        rating_average: 4.5,
        rating_count: 2,
        reviews: [
          {
            id: 1,
            author: "Ana",
            rating: 5,
            description: "Excelente almuerzo",
            created_at: "2026-10-25",
          },
          {
            id: 2,
            author: "Luis",
            rating: 4,
            description: "Muy buena comida",
            created_at: "2026-10-25",
          },
        ],
      },
    }
    render(
      <Index
        {...props}
        schedules={[reviewedSchedule, ...schedules.slice(1)]}
      />,
    )
    const cartBefore = window.sessionStorage.getItem(cartStorageKey)
    await applyFilter(user)
    expectFilteredDay(26)
    await user.click(
      screen.getByRole("button", { name: "Agregar Plato 1 d\u00eda 26" }),
    )
    expect(
      screen.getByRole("heading", { name: "Opiniones del plato" }),
    ).toBeInTheDocument()
    expect(screen.getByText("4.5 (2)")).toBeInTheDocument()
    expect(screen.getByText("Ana")).toBeInTheDocument()
    expect(screen.getByText("Excelente almuerzo")).toBeInTheDocument()
    expect(screen.getByText("Luis")).toBeInTheDocument()
    expect(screen.getByText("Muy buena comida")).toBeInTheDocument()
    await user.click(screen.getByRole("button", { name: "Volver" }))
    expectFilteredDay(26)
    expect(window.sessionStorage.getItem(cartStorageKey)).toBe(cartBefore)
  })

  it("keeps multiple provider IDs after detail navigation and day changes", async () => {
    const user = userEvent.setup()
    render(<Index {...props} />)
    await applyFilter(user)
    expectFilteredDay(26)

    await user.click(
      screen.getByRole("button", { name: "Agregar Plato 1 día 26" }),
    )
    await user.click(screen.getByRole("button", { name: "Volver" }))
    expectFilteredDay(26)

    await user.click(screen.getByRole("radio", { name: /27/ }))
    expectFilteredDay(27)
    await user.click(
      screen.getByRole("button", { name: "Agregar Plato 2 día 27" }),
    )
    await user.click(screen.getByRole("button", { name: "Volver" }))
    expectFilteredDay(27)

    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )
    expect(screen.getAllByLabelText("La Cocina")[0]).toBeChecked()
    expect(screen.getAllByLabelText("La Cocina")[1]).not.toBeChecked()
    expect(screen.getByLabelText("Otro proveedor")).toBeChecked()
    await user.click(screen.getByLabelText("Todos"))
    await user.click(screen.getByRole("button", { name: "Cancelar" }))
    expectFilteredDay(27)

    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )
    await user.click(screen.getByLabelText("Todos"))
    await user.click(screen.getByRole("button", { name: "Aplicar" }))
    expect(screen.getByText("Plato 3 día 27")).toBeInTheDocument()
  })

  it("keeps the filter when adding and editing without changing other cart lines or pricing inputs", async () => {
    const user = userEvent.setup()
    const existing: CartItem = {
      ...schedules[2],
      cartId: "existing",
      quantity: 2,
      notes: "Sin sal",
      selections: {},
      benefits: [],
    }
    window.sessionStorage.setItem(cartStorageKey, JSON.stringify([existing]))
    render(<Index {...props} />)
    await applyFilter(user)

    await user.click(
      screen.getByRole("button", { name: "Agregar Plato 1 día 26" }),
    )
    await user.click(screen.getByRole("button", { name: "Agregar uno" }))
    await user.type(screen.getByLabelText("Notas para este plato"), "Sin salsa")
    await user.click(screen.getByRole("button", { name: /^Agregar$/ }))
    expectFilteredDay(26)

    const added = JSON.parse(
      window.sessionStorage.getItem(cartStorageKey)!,
    ) as CartItem[]
    expect(added[0]).toEqual(existing)
    expect(added[1]).toMatchObject({ id: 261, quantity: 2, notes: "Sin salsa" })
    await waitFor(() =>
      expect(priceItems).toHaveBeenCalledWith([
        { schedule_id: 263, quantity: 2, benefits: [] },
        { schedule_id: 261, quantity: 2, benefits: [] },
      ]),
    )

    await user.click(screen.getByRole("button", { name: /Plato 1 día 26/ }))
    await user.click(screen.getByRole("button", { name: "Agregar uno" }))
    await user.click(screen.getByRole("button", { name: /^Modificar$/ }))
    expectFilteredDay(26)
    const edited = JSON.parse(
      window.sessionStorage.getItem(cartStorageKey)!,
    ) as CartItem[]
    expect(edited[0]).toEqual(existing)
    expect(edited[1]).toMatchObject({
      quantity: 3,
      notes: "Sin salsa",
      menu: { price: 300 },
    })
    await waitFor(() =>
      expect(priceItems).toHaveBeenCalledWith([
        { schedule_id: 263, quantity: 2, benefits: [] },
        { schedule_id: 261, quantity: 3, benefits: [] },
      ]),
    )
  })
})

describe("Clearing consumer provider filters", () => {
  it.each(["Todos", "individual deselection"])(
    "restores all offers with %s without changing cart data or totals",
    async (method) => {
      const user = userEvent.setup()
      const existing: CartItem = {
        ...schedules[2],
        cartId: "existing",
        quantity: 2,
        notes: "Sin sal",
        selections: {},
        benefits: [],
      }
      window.sessionStorage.setItem(cartStorageKey, JSON.stringify([existing]))
      render(<Index {...props} />)
      await applyFilter(user)
      expectFilteredDay(26)
      const summary = await screen.findByRole("heading", {
        name: "2 platos · $300",
      })
      const total = summary.textContent

      await user.click(
        screen.getByRole("button", { name: "Filtrar por proveedores" }),
      )
      if (method === "Todos") {
        await user.click(screen.getByLabelText("Todos"))
      } else {
        await user.click(screen.getAllByLabelText("La Cocina")[0])
        await user.click(screen.getByRole("button", { name: "Aplicar" }))
        expect(screen.queryByText("Plato 1 día 26")).not.toBeInTheDocument()
        expect(screen.getByText("Plato 2 día 26")).toBeInTheDocument()
        await user.click(
          screen.getByRole("button", { name: "Filtrar por proveedores" }),
        )
        await user.click(screen.getByLabelText("Otro proveedor"))
        expect(screen.getByLabelText("Todos")).toBeChecked()
      }
      await user.click(screen.getByRole("button", { name: "Aplicar" }))
      for (const id of [1, 2, 3]) {
        expect(screen.getByText(`Plato ${id} día 26`)).toBeInTheDocument()
      }
      expect(
        JSON.parse(window.sessionStorage.getItem(cartStorageKey)!),
      ).toEqual([existing])
      expect(screen.getByRole("heading", { level: 3 }).textContent).toBe(total)

      await user.click(screen.getByRole("radio", { name: /27/ }))
      for (const id of [1, 2, 3]) {
        expect(screen.getByText(`Plato ${id} día 27`)).toBeInTheDocument()
        expect(screen.queryByText(`Plato ${id} día 26`)).not.toBeInTheDocument()
      }
      await user.click(screen.getByRole("radio", { name: /28/ }))
      expect(
        screen.getByText(
          "Todavía no hay viandas publicadas para este día. Volvé a consultar más tarde.",
        ),
      ).toBeInTheDocument()
      expect(
        JSON.parse(window.sessionStorage.getItem(cartStorageKey)!),
      ).toEqual([existing])
    },
  )

  it("restores available dishes after clearing a provider with no offer and clears an empty day", async () => {
    const user = userEvent.setup()
    render(
      <Index
        {...props}
        schedules={schedules.filter((item) => item.menu.provider_id === 2)}
      />,
    )
    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )
    await user.click(screen.getAllByLabelText("La Cocina")[1])
    await user.click(screen.getByLabelText("Otro proveedor"))
    await user.click(screen.getByRole("button", { name: "Aplicar" }))
    expect(
      screen.getByText(/No encontramos viandas disponibles entre/),
    ).toBeInTheDocument()
    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )
    await user.click(screen.getByLabelText("Todos"))
    await user.click(screen.getByRole("button", { name: "Aplicar" }))
    expect(screen.getByText("Plato 2 día 26")).toBeInTheDocument()

    await applyFilter(user)
    await user.click(screen.getByRole("radio", { name: /28/ }))
    expect(
      screen.getByText(/No encontramos viandas disponibles entre/),
    ).toBeInTheDocument()
    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )
    await user.click(screen.getByLabelText("Todos"))
    await user.click(screen.getByRole("button", { name: "Aplicar" }))
    expect(
      screen.getByText(
        "Todavía no hay viandas publicadas para este día. Volvé a consultar más tarde.",
      ),
    ).toBeInTheDocument()
  })
})

it("keeps all 140 note characters after the asynchronous dish price updates", async () => {
  const user = userEvent.setup()
  let resolvePricing!: (value: Awaited<ReturnType<typeof priceItems>>) => void
  const pendingPricing = new Promise<Awaited<ReturnType<typeof priceItems>>>(
    (resolve) => {
      resolvePricing = resolve
    },
  )
  vi.mocked(priceItems).mockReturnValueOnce(pendingPricing)
  render(<Index {...props} />)
  await user.click(
    screen.getByRole("button", { name: "Agregar Plato 1 día 26" }),
  )
  const notes = "a".repeat(140)
  await user.type(screen.getByLabelText("Notas para este plato"), notes)
  await waitFor(() => expect(priceItems).toHaveBeenCalled())
  await act(async () => {
    resolvePricing({
      subtotal: 300,
      discount: 150,
      total: 150,
      lines: [
        {
          subtotal: 300,
          discount: 150,
          total: 150,
          tiers: [
            { id: 1, name: "Base", percentage: 50, quantity: 1, discount: 150 },
          ],
        },
      ],
      subsidizedQuantity: 1,
      fullPriceQuantity: 0,
    })
    await pendingPricing
  })
  expect(screen.getByText("$150")).toBeInTheDocument()
  expect(screen.getByLabelText("Notas para este plato")).toHaveValue(notes)
  expect(screen.getByText("140/140")).toBeInTheDocument()
})
