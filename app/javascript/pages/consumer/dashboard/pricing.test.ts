import { describe, expect, it } from "vitest"

import { type Benefit, type PricedItem, priceItems } from "./pricing"

// Los mismos casos que spec/services/order_pricing_spec.rb: lo que muestra el
// carrito tiene que coincidir con lo que guarda el servidor.
const benefit = (overrides: Partial<Benefit> = {}): Benefit => ({
  limit: 5,
  used: 0,
  percentage: 50,
  monthly_limit: 20,
  monthly_used: 0,
  monthly_remaining: 20,
  specials: [],
  ...overrides,
})

const special = (
  overrides: Partial<Benefit["specials"][number]> = {},
): Benefit["specials"][number] => ({
  id: 1,
  name: "Premio",
  percentage: 30,
  remaining: null,
  due_date: null,
  ...overrides,
})

const item = (quantity: number, overrides: Partial<PricedItem> = {}) => ({
  key: "a",
  date: "2026-09-16",
  price: 300,
  quantity,
  ...overrides,
})

describe("priceItems", () => {
  it("adds the special subsidy to the base one in a single combined line", () => {
    const pricing = priceItems([item(1)], benefit({ specials: [special()] }))

    expect(pricing.total).toBe(60)
    expect(pricing.lines.a.tiers).toEqual([
      { percentage: 80, quantity: 1, discount: 240 },
    ])
  })

  it("caps the sum at 100%", () => {
    const pricing = priceItems(
      [item(1)],
      benefit({ specials: [special({ percentage: 100 })] }),
    )

    expect(pricing.total).toBe(0)
    expect(pricing.lines.a.tiers).toEqual([
      { percentage: 100, quantity: 1, discount: 300 },
    ])
  })

  it("adds up two specials at the same time", () => {
    const pricing = priceItems(
      [item(1)],
      benefit({
        specials: [
          special({ id: 1, percentage: 25 }),
          special({ id: 2, percentage: 10 }),
        ],
      }),
    )

    expect(pricing.total).toBe(45)
    expect(pricing.lines.a.tiers).toEqual([
      expect.objectContaining({ percentage: 85 }),
    ])
  })

  // Figma no cubre este caso: una línea por cada porcentaje distinto.
  it("splits a dish into one line per combined percentage", () => {
    const pricing = priceItems(
      [item(3)],
      benefit({ specials: [special({ remaining: 1 })] }),
    )

    expect(pricing.total).toBe(360)
    expect(pricing.lines.a.tiers).toEqual([
      { percentage: 80, quantity: 1, discount: 240 },
      { percentage: 50, quantity: 2, discount: 300 },
    ])
  })

  it("covers only as many meals as the special has uses left", () => {
    const pricing = priceItems(
      [item(3)],
      benefit({
        monthly_remaining: 1,
        specials: [special({ remaining: 1 })],
      }),
    )

    // 1ª con 80%, 2ª y 3ª a precio completo.
    expect(pricing.total).toBe(660)
    expect(pricing.subsidizedQuantity).toBe(1)
    expect(pricing.fullPriceQuantity).toBe(2)
    expect(pricing.lines.a.tiers).toEqual([
      { percentage: 80, quantity: 1, discount: 240 },
    ])
  })

  it("applies the special once the monthly quota is used up", () => {
    const pricing = priceItems(
      [item(2)],
      benefit({ monthly_remaining: 0, specials: [special()] }),
    )

    expect(pricing.total).toBe(420)
    expect(pricing.fullPriceQuantity).toBe(0)
  })

  it("applies the special without a base benefit", () => {
    const pricing = priceItems(
      [item(1)],
      benefit({ percentage: 0, specials: [special()] }),
    )

    expect(pricing.total).toBe(210)
  })

  it("uses the delivery date to decide if a special is still valid", () => {
    const specials = [special({ due_date: "2026-09-16" })]

    expect(priceItems([item(1)], benefit({ specials })).total).toBe(60)
    expect(
      priceItems([item(1, { date: "2026-09-17" })], benefit({ specials }))
        .total,
    ).toBe(150)
  })

  it("spends the special uses on the first items of the cart", () => {
    const pricing = priceItems(
      [item(1, { key: "a" }), item(1, { key: "b" })],
      benefit({ percentage: 0, specials: [special({ remaining: 1 })] }),
    )

    expect(pricing.lines.a.total).toBe(210)
    expect(pricing.lines.b.total).toBe(300)
  })

  it("keeps the benefit line at zero when nothing is subsidized", () => {
    const pricing = priceItems([item(1)], benefit({ monthly_remaining: 0 }))

    expect(pricing.lines.a.tiers).toEqual([
      { percentage: 50, quantity: 0, discount: 0 },
    ])
  })

  it("covers all items when a special subsidy has unlimited uses (remaining is null)", () => {
    const pricing = priceItems(
      [item(5)],
      benefit({
        percentage: 0,
        specials: [special({ remaining: null, percentage: 20 })],
      }),
    )

    expect(pricing.total).toBe(1200)
    expect(pricing.fullPriceQuantity).toBe(0)
    expect(pricing.lines.a.tiers).toEqual([
      { percentage: 20, quantity: 5, discount: 300 },
    ])
  })
})
