import { afterEach, describe, expect, it, vi } from "vitest"

import { pricingOrders } from "@/routes"

import { priceItems } from "./pricing"

describe("priceItems", () => {
  afterEach(() => {
    vi.restoreAllMocks()
  })

  it("envía los items al backend y devuelve el pricing", async () => {
    const items = [
      { schedule_id: 1, quantity: 2 },
      { schedule_id: 2, quantity: 1 },
    ]

    const pricing = {
      subtotal: 300,
      discount: 100,
      total: 200,
      lines: {},
      subsidizedQuantity: 2,
      fullPriceQuantity: 1,
    }

    const fetchMock = vi.spyOn(globalThis, "fetch").mockResolvedValue(
      new Response(JSON.stringify(pricing), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }),
    )

    const result = await priceItems(items)

    expect(fetchMock).toHaveBeenCalledWith(
      pricingOrders().url,
      expect.objectContaining({
        method: "POST",
        body: JSON.stringify({ items }),
      }),
    )

    expect(result).toEqual(pricing)
  })

  it("lanza un error si el backend responde con error", async () => {
    vi.spyOn(globalThis, "fetch").mockResolvedValue(
      new Response(null, { status: 500 }),
    )

    await expect(priceItems([])).rejects.toThrow(
      "Error al calcular precios: 500",
    )
  })

  it("devuelve el pricing correctamente cuando un plato no tiene subsidio por superar el precio máximo", async () => {
    const items = [
      { schedule_id: 10, quantity: 1 }, // plato caro sin descuento
      { schedule_id: 11, quantity: 1 }, // plato dentro del límite con descuento
    ]

    const pricing = {
      subtotal: 550,
      discount: 100,
      total: 450,
      lines: {
        "10": { subtotal: 350, discount: 0, total: 350, tiers: [] },
        "11": {
          subtotal: 200,
          discount: 100,
          total: 100,
          tiers: [
            {
              name: "Subsidio Base",
              percentage: 50,
              quantity: 1,
              discount: 100,
            },
          ],
        },
      },
      subsidizedQuantity: 1,
      fullPriceQuantity: 1,
    }

    vi.spyOn(globalThis, "fetch").mockResolvedValue(
      new Response(JSON.stringify(pricing), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }),
    )

    const result = await priceItems(items)

    expect(result).toEqual(pricing)
    expect(result.lines["10"]?.discount).toBe(0)
    expect(result.lines["11"]?.discount).toBe(100)
    expect(result.subsidizedQuantity).toBe(1)
    expect(result.fullPriceQuantity).toBe(1)
  })

  it("lanza un error si el backend responde con error 422 o 400", async () => {
    vi.spyOn(globalThis, "fetch").mockResolvedValue(
      new Response(null, { status: 422 }),
    )

    await expect(priceItems([])).rejects.toThrow(
      "Error al calcular precios: 422",
    )
  })
})
