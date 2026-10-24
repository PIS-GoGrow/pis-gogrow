import { pricingOrders } from "@/routes"

import type { CartItem } from "./consumer-types"

export interface PricedItem {
  schedule_id: number
  quantity: number
  benefits: number[]
}

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

// No hace ningún cálculo: Obtiene los precios de la orden desde el backend
export async function priceItems(items: PricedItem[]): Promise<Pricing> {
  const response = await fetch(pricingOrders().url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      "X-Requested-With": "XMLHttpRequest",
      "X-CSRF-Token":
        document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')
          ?.content ?? "",
    },
    body: JSON.stringify({ items }),
    credentials: "same-origin",
  })

  if (!response.ok) {
    throw new Error(`Error al calcular precios: ${response.status}`)
  }

  return response.json() as Promise<Pricing>
}

export const lastUnitsLine = (
  n: number,
  k: number,
  line: PricedLine,
): PricedLine => {
  if (!line) return line

  if (n <= 0) return { subtotal: 0, discount: 0, total: 0, tiers: [] }

  const units = Math.min(Math.max(k, 0), n)
  const start = n - units // posición (0-indexed) desde la que cuentan las últimas k

  const offset = 0
  const tiers: DiscountTier[] = []

  for (const tier of line.tiers) {
    const tierStart = offset
    const tierEnd = offset + tier.quantity

    // unidades de este tier que caen dentro de la ventana [start, n)
    const overlap = Math.max(0, tierEnd - Math.max(tierStart, start))
    if (overlap === 0) continue

    tiers.push({
      ...tier,
      quantity: overlap,
      discount: (tier.discount * overlap) / tier.quantity,
    })
  }

  const subtotal = (line.subtotal * units) / n
  const discount = tiers.reduce((sum, t) => sum + t.discount, 0)

  return { subtotal, discount, total: subtotal - discount, tiers }
}

type Quantifiable = Pick<CartItem, "id" | "quantity" | "benefits">
export const cartPricedItem = (items: Quantifiable[]): PricedItem[] => {
  return items.map((item) => {
    return {
      schedule_id: item.id,
      quantity: item.quantity,
        benefits: item.benefits,
    }
  })
}
