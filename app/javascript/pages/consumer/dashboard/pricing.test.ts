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
})
