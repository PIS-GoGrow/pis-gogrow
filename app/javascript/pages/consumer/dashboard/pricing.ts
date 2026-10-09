import type { ConsumerDashboardIndex } from "@/types"

import type { CartItem } from "./consumer-types"

export type Benefit = ConsumerDashboardIndex["benefit"]

export interface PricedItem {
  key: string
  date: string
  price: number
  quantity: number
}

// Las viandas de un plato que comparten el mismo porcentaje combinado.
export interface DiscountTier {
  percentage: number
  quantity: number
  discount: number
}

export interface PricedLine {
  subtotal: number
  discount: number
  total: number
  tiers: DiscountTier[]
}

export interface Pricing {
  subtotal: number
  discount: number
  total: number
  lines: Record<string, PricedLine>
  subsidizedQuantity: number
  fullPriceQuantity: number
}

// Replica OrderPricing del servidor: el base cubre las viandas del cupo
// mensual y cada especial las de sus usos restantes, sobre las primeras viandas
// en el orden de los ítems; en una vianda los porcentajes se suman hasta 100%.
export function priceItems(items: PricedItem[], benefit: Benefit): Pricing {
  let baseLeft =
    benefit.percentage > 0 ? Math.max(benefit.monthly_remaining, 0) : 0
  const specialLeft = new Map(
    benefit.specials.map((special) => [special.id, special.remaining]),
  )
  const lines: Record<string, PricedLine> = {}
  let subsidizedQuantity = 0
  let fullPriceQuantity = 0

  items.forEach((item) => {
    const baseUnits = Math.min(item.quantity, baseLeft)
    baseLeft -= baseUnits
    subsidizedQuantity += baseUnits

    const coverage = [{ percentage: benefit.percentage, units: baseUnits }]
    benefit.specials.forEach((special) => {
      if (special.due_date !== null && special.due_date < item.date) return

      const left = specialLeft.get(special.id) ?? null
      const units =
        left === null ? item.quantity : Math.min(item.quantity, left)
      if (left !== null) specialLeft.set(special.id, left - units)
      coverage.push({ percentage: special.percentage, units })
    })

    const tiers: DiscountTier[] = []
    for (let unit = 0; unit < item.quantity; unit++) {
      const percentage = Math.min(
        coverage.reduce(
          (sum, entry) => sum + (unit < entry.units ? entry.percentage : 0),
          0,
        ),
        100,
      )
      if (percentage === 0) {
        fullPriceQuantity += 1
        continue
      }

      const tier = tiers.find((entry) => entry.percentage === percentage)
      const discount = (item.price * percentage) / 100
      if (tier) {
        tier.quantity += 1
        tier.discount += discount
      } else {
        tiers.push({ percentage, quantity: 1, discount })
      }
    }

    const subtotal = item.price * item.quantity
    const discount = tiers.reduce((sum, tier) => sum + tier.discount, 0)
    lines[item.key] = {
      subtotal,
      discount,
      total: subtotal - discount,
      // Sin viandas subsidiadas el resumen igual muestra la línea del
      // beneficio, en cero.
      tiers: tiers.length
        ? tiers
        : [{ percentage: benefit.percentage, quantity: 0, discount: 0 }],
    }
  })

  const subtotal = Object.values(lines).reduce(
    (sum, line) => sum + line.subtotal,
    0,
  )
  const discount = Object.values(lines).reduce(
    (sum, line) => sum + line.discount,
    0,
  )

  return {
    subtotal,
    discount,
    total: subtotal - discount,
    lines,
    subsidizedQuantity,
    fullPriceQuantity,
  }
}

export const cartPricedItem = (item: CartItem): PricedItem => ({
  key: item.cartId,
  date: item.date,
  price: item.menu.price,
  quantity: item.quantity,
})
