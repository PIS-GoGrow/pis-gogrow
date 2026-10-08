import type { OrderDeliveryMethod, ProviderOrder } from "@/types"

export type StatusFilter = "pending" | "confirmed" | "all"
export type DeliveryFilter = "all" | OrderDeliveryMethod

export interface OrderFilters {
  status: StatusFilter
  delivery: DeliveryFilter
  search: string
}

export interface OrderDay {
  date: string
  orders: ProviderOrder[]
}

// Los controles y la lista de días son dos grillas; comparten columnas para
// que la lista y el panel de pedidos queden alineados con sus controles.
export const ordersColumns =
  "lg:grid-cols-[minmax(0,320px)_minmax(0,1fr)] lg:gap-x-12"

export const noFilters: OrderFilters = {
  status: "all",
  delivery: "all",
  search: "",
}

export function hasActiveFilters({ status, delivery, search }: OrderFilters) {
  return status !== "all" || delivery !== "all" || search.trim() !== ""
}

function normalize(text: string) {
  return text
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "")
    .toLowerCase()
}

export function filterOrders(
  orders: ProviderOrder[],
  { status, delivery, search }: OrderFilters,
  searchableText: (order: ProviderOrder) => (string | null)[],
) {
  const words = normalize(search).split(/\s+/).filter(Boolean)

  return orders.filter((order) => {
    if (status !== "all" && order.status !== status) return false
    if (delivery !== "all" && order.delivery_method !== delivery) return false
    if (words.length === 0) return true

    const text = normalize(searchableText(order).filter(Boolean).join(" "))

    return words.every((word) => text.includes(word))
  })
}

// Conserva el orden en que llegan los pedidos: el servidor ya los entrega
// ordenados por fecha de entrega.
export function groupByDate(orders: ProviderOrder[]): OrderDay[] {
  const days = new Map<string, ProviderOrder[]>()

  for (const order of orders) {
    if (!order.date) continue

    days.set(order.date, [...(days.get(order.date) ?? []), order])
  }

  return Array.from(days, ([date, dayOrders]) => ({
    date,
    orders: dayOrders,
  }))
}

export function withToday(days: OrderDay[], today: string): OrderDay[] {
  if (days.some((day) => day.date === today)) return days

  return [{ date: today, orders: [] }, ...days]
}

export function initialDate(days: OrderDay[], today: string) {
  return days.find((day) => day.date === today)?.date ?? days[0]?.date ?? null
}

export function summarize(orders: ProviderOrder[]) {
  const total = orders.reduce((sum, order) => sum + order.price, 0)

  return {
    meals: orders.reduce((sum, order) => sum + (order.amount ?? 0), 0),
    total: Math.round(total * 100) / 100,
  }
}

// Parte el string ISO en lugar de crear un Date, que depende de la zona
// horaria del navegador.
export function formatDayDate(date: string) {
  const [, month, day] = date.split("-")

  return `${day}/${month}`
}
