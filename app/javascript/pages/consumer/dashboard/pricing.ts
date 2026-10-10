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
  name?: string
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

    const coverage: { name?: string; percentage: number; units: number }[] = [
      { percentage: benefit.percentage, units: baseUnits },
    ]
    benefit.specials.forEach((special) => {
      if (special.due_date !== null && special.due_date < item.date) return

      const left = specialLeft.get(special.id) ?? null
      const units =
        left === null ? item.quantity : Math.min(item.quantity, left)
      if (left !== null) specialLeft.set(special.id, left - units)
      coverage.push({
        name: special.name,
        percentage: special.percentage,
        units,
      })
    })

    const tiers: DiscountTier[] = []
    for (let unit = 0; unit < item.quantity; unit++) {
      const activeBenefits = coverage.filter(
        (entry) => unit < entry.units && entry.percentage > 0,
      )
      const totalPercentage = activeBenefits.reduce(
        (sum, entry) => sum + entry.percentage,
        0,
      )

      if (totalPercentage === 0) {
        fullPriceQuantity += 1
        continue
      }

      let remainingAllowed = 100
      for (const entry of activeBenefits) {
        const applicablePercentage = Math.min(
          entry.percentage,
          remainingAllowed,
        )
        remainingAllowed -= applicablePercentage

        if (applicablePercentage <= 0) continue

        const discount = (item.price * applicablePercentage) / 100
        const existing = tiers.find(
          (t) => t.name === entry.name && t.percentage === applicablePercentage,
        )
        if (existing) {
          existing.quantity += 1
          existing.discount += discount
        } else {
          tiers.push({
            name: entry.name,
            percentage: applicablePercentage,
            quantity: 1,
            discount,
          })
        }
      }
    }

    const subtotal = item.price * item.quantity
    const discount = tiers.reduce((sum, tier) => sum + tier.discount, 0)
    lines[item.key] = {
      subtotal,
      discount,
      total: subtotal - discount,
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
