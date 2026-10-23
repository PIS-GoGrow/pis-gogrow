import { describe, expect, it } from "vitest"

import type { AdminConsumerMonth } from "@/types"

import {
  emptyConsumerHistoryFilters,
  filterConsumerHistory,
  hasConsumerHistoryFilters,
} from "./admin-consumer-history"

const month: AdminConsumerMonth = {
  key: "2026-10",
  year: 2026,
  label: "Octubre 2026",
  amount: 600,
  subsidy: 400,
  status: "pending",
  providers: [
    { id: 1, name: "Tu Viandita", amount: 400, status: "pending" },
    { id: 2, name: "Endulzate", amount: 200, status: "approved" },
  ],
  orders: [
    {
      id: 1,
      date: "14/10",
      provider_id: 1,
      provider_name: "Tu Viandita",
      amount: 1,
      subsidy: 200,
      charged: 200,
    },
    {
      id: 2,
      date: "15/10",
      provider_id: 1,
      provider_name: "Tu Viandita",
      amount: 1,
      subsidy: 0,
      charged: 200,
    },
    {
      id: 3,
      date: "16/10",
      provider_id: 2,
      provider_name: "Endulzate",
      amount: 1,
      subsidy: 200,
      charged: 200,
    },
  ],
}

describe("filterConsumerHistory", () => {
  it("devuelve todo y recalcula los mismos totales sin filtros", () => {
    expect(filterConsumerHistory(month, emptyConsumerHistoryFilters())).toEqual(
      {
        orders: month.orders,
        providers: month.providers,
        total: 600,
        subsidy: 400,
      },
    )
  })

  it("combina proveedor, estado y subsidio sobre los mismos pedidos", () => {
    const result = filterConsumerHistory(month, {
      providers: new Set([1]),
      status: "pending",
      subsidy: "with",
    })

    expect(result.orders.map((order) => order.id)).toEqual([1])
    expect(result.providers).toEqual([
      { id: 1, name: "Tu Viandita", amount: 200, status: "pending" },
    ])
    expect(result.total).toBe(200)
    expect(result.subsidy).toBe(200)
  })

  it("filtra el estado de la cuenta del proveedor, no el pedido", () => {
    const result = filterConsumerHistory(month, {
      ...emptyConsumerHistoryFilters(),
      status: "approved",
    })

    expect(result.orders.map((order) => order.id)).toEqual([3])
    expect(result.providers.map((provider) => provider.name)).toEqual([
      "Endulzate",
    ])
  })

  it("distingue consumos sin subsidio aplicado", () => {
    const result = filterConsumerHistory(month, {
      ...emptyConsumerHistoryFilters(),
      subsidy: "without",
    })

    expect(result.orders.map((order) => order.id)).toEqual([2])
    expect(result.subsidy).toBe(0)
  })

  it("devuelve totales vacíos cuando no hay coincidencias", () => {
    const result = filterConsumerHistory(month, {
      providers: new Set([2]),
      status: "pending",
      subsidy: "all",
    })

    expect(result).toEqual({ orders: [], providers: [], total: 0, subsidy: 0 })
  })
})

describe("hasConsumerHistoryFilters", () => {
  it("detecta cualquier filtro activo", () => {
    expect(hasConsumerHistoryFilters(emptyConsumerHistoryFilters())).toBe(false)
    expect(
      hasConsumerHistoryFilters({
        ...emptyConsumerHistoryFilters(),
        providers: new Set([1]),
      }),
    ).toBe(true)
    expect(
      hasConsumerHistoryFilters({
        ...emptyConsumerHistoryFilters(),
        status: "pending",
      }),
    ).toBe(true)
    expect(
      hasConsumerHistoryFilters({
        ...emptyConsumerHistoryFilters(),
        subsidy: "with",
      }),
    ).toBe(true)
  })
})
