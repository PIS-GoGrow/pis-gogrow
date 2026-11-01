import { pricingOrders } from "@/routes"

import type { CartItem } from "./consumer-types"

export interface PricedItem {
  schedule_id: number
  quantity: number
  benefits: number[]
}

export interface DiscountTier {
  id: number
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
  lines: PricedLine[]
  subsidizedQuantity: number
  fullPriceQuantity: number
}

// No hace ningún cálculo: Obtiene los precios de la orden desde el backend
export async function priceItems(
  items: PricedItem[],
  orderId?: number,
): Promise<Pricing> {
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
    body: JSON.stringify({ items, order_id: orderId }),
    credentials: "same-origin",
  })

  if (!response.ok) {
    throw new Error(`Error al calcular precios: ${response.status}`)
  }

  return response.json() as Promise<Pricing>
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
