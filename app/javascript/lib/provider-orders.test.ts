import { describe, expect, it } from "vitest"

import type { ProviderOrder } from "@/types"

import {
  filterOrders,
  groupByDate,
  initialDate,
  noFilters,
  summarize,
} from "./provider-orders"

function order(overrides: Partial<ProviderOrder>): ProviderOrder {
  return {
    id: 1,
    status: "pending",
    amount: 1,
    notes: null,
    delivery_method: "office",
    price: 300,
    date: "2026-10-06",
    time: "10:00",
    consumer_name: "Bruno Pérez",
    consumer_company: "GoGrow",
    menu_name: "Milanesa de pollo",
    address: "Av. 18 de Julio 1006",
    rejectable: true,
    ...overrides,
  }
}

const text = (o: ProviderOrder) => [o.consumer_name, o.menu_name, o.address]

describe("filterOrders", () => {
  const orders = [
    order({ id: 1, status: "pending", delivery_method: "office" }),
    order({
      id: 2,
      status: "confirmed",
      delivery_method: "home",
      consumer_name: "Matías Rodríguez",
      menu_name: "Wok de verduras",
    }),
    order({ id: 3, status: "cancelled", delivery_method: "home" }),
  ]

  it("devuelve todo sin filtros", () => {
    expect(filterOrders(orders, noFilters, text)).toHaveLength(3)
  })

  it("filtra por estado", () => {
    const result = filterOrders(
      orders,
      { ...noFilters, status: "confirmed" },
      text,
    )

    expect(result.map((o) => o.id)).toEqual([2])
  })

  it("filtra por tipo de entrega", () => {
    const result = filterOrders(
      orders,
      { ...noFilters, delivery: "home" },
      text,
    )

    expect(result.map((o) => o.id)).toEqual([2, 3])
  })

  it("busca sin distinguir acentos ni mayúsculas", () => {
    const result = filterOrders(
      orders,
      { ...noFilters, search: "RODRIGUEZ" },
      text,
    )

    expect(result.map((o) => o.id)).toEqual([2])
  })

  it("pide que aparezcan todas las palabras, en cualquier orden", () => {
    const result = filterOrders(
      orders,
      { ...noFilters, search: "wok matias" },
      text,
    )

    expect(result.map((o) => o.id)).toEqual([2])
  })

  it("ignora los campos vacíos al buscar", () => {
    const result = filterOrders(
      orders,
      { ...noFilters, search: "pollo" },
      (o) => [null, o.menu_name],
    )

    expect(result.map((o) => o.id)).toEqual([1, 3])
  })

  it("combina estado, entrega y búsqueda", () => {
    const result = filterOrders(
      orders,
      { status: "pending", delivery: "home", search: "pollo" },
      text,
    )

    expect(result).toEqual([])
  })
})

describe("groupByDate", () => {
  it("agrupa por fecha de entrega conservando el orden", () => {
    const days = groupByDate([
      order({ id: 1, date: "2026-10-06" }),
      order({ id: 2, date: "2026-10-07" }),
      order({ id: 3, date: "2026-10-06" }),
    ])

    expect(days.map((day) => day.date)).toEqual(["2026-10-06", "2026-10-07"])
    expect(days[0].orders.map((o) => o.id)).toEqual([1, 3])
  })

  it("descarta los pedidos sin fecha", () => {
    expect(groupByDate([order({ date: null })])).toEqual([])
  })
})

describe("initialDate", () => {
  const days = groupByDate([
    order({ date: "2026-10-07" }),
    order({ date: "2026-10-08" }),
  ])

  it("elige hoy si está", () => {
    expect(initialDate(days, "2026-10-08")).toBe("2026-10-08")
  })

  it("elige el primer día si hoy no está", () => {
    expect(initialDate(days, "2026-10-06")).toBe("2026-10-07")
  })

  it("devuelve null sin días", () => {
    expect(initialDate([], "2026-10-06")).toBeNull()
  })
})

describe("summarize", () => {
  it("suma viandas y monto de los pedidos pendientes y confirmados", () => {
    const summary = summarize([
      order({ amount: 2, price: 600.1, status: "pending" }),
      order({ amount: null, price: 0.2, status: "confirmed" }),
      order({ amount: 3, price: 1200, status: "confirmed" }),
    ])

    expect(summary).toEqual({ meals: 5, total: 1800.3 })
  })

  it("no cuenta los pedidos cancelados", () => {
    const summary = summarize([
      order({ amount: 2, price: 600 }),
      order({ amount: 1, price: 300, status: "cancelled" }),
    ])

    expect(summary).toEqual({ meals: 2, total: 600 })
  })

  it("no cuenta los pedidos rechazados", () => {
    const summary = summarize([
      order({ amount: 2, price: 600 }),
      order({ amount: 1, price: 300, status: "rejected" }),
    ])

    expect(summary).toEqual({ meals: 2, total: 600 })
  })

  it("devuelve ceros si todos están cancelados o rechazados", () => {
    const summary = summarize([
      order({ amount: 1, price: 300, status: "cancelled" }),
      order({ amount: 1, price: 300, status: "rejected" }),
    ])

    expect(summary).toEqual({ meals: 0, total: 0 })
  })

  it("devuelve ceros sin pedidos", () => {
    expect(summarize([])).toEqual({ meals: 0, total: 0 })
  })
})
