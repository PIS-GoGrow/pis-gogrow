import type { AdminConsumerMonth, PaymentStatus } from "@/types"

export type SubsidyFilter = "all" | "with" | "without"

export interface ConsumerHistoryFilters {
  providers: Set<number>
  status: PaymentStatus | "all"
  subsidy: SubsidyFilter
}

export function emptyConsumerHistoryFilters(): ConsumerHistoryFilters {
  return {
    providers: new Set(),
    status: "all",
    subsidy: "all",
  }
}

export function hasConsumerHistoryFilters({
  providers,
  status,
  subsidy,
}: ConsumerHistoryFilters) {
  return providers.size > 0 || status !== "all" || subsidy !== "all"
}

export function filterConsumerHistory(
  month: AdminConsumerMonth,
  filters: ConsumerHistoryFilters,
) {
  if (!hasConsumerHistoryFilters(filters)) {
    return {
      orders: month.orders,
      providers: month.providers,
      total: month.amount,
      subsidy: month.subsidy,
    }
  }

  const statusByProvider = new Map(
    month.providers.map((provider) => [provider.id, provider.status]),
  )

  const orders = month.orders.filter((order) => {
    const providerId = order.provider_id

    if (
      filters.providers.size > 0 &&
      (!providerId || !filters.providers.has(providerId))
    ) {
      return false
    }

    if (
      filters.status !== "all" &&
      (!providerId || statusByProvider.get(providerId) !== filters.status)
    ) {
      return false
    }

    if (filters.subsidy === "with" && order.subsidy <= 0) return false
    if (filters.subsidy === "without" && order.subsidy > 0) return false

    return true
  })

  const providerIds = new Set(
    orders.flatMap((order) => (order.provider_id ? [order.provider_id] : [])),
  )
  const amountByProvider = orders.reduce((amounts, order) => {
    if (!order.provider_id) return amounts

    amounts.set(
      order.provider_id,
      (amounts.get(order.provider_id) ?? 0) + order.charged,
    )
    return amounts
  }, new Map<number, number>())

  const providers = month.providers
    .filter((provider) => providerIds.has(provider.id))
    .map((provider) => ({
      ...provider,
      amount: roundMoney(amountByProvider.get(provider.id) ?? 0),
    }))

  return {
    orders,
    providers,
    total: roundMoney(orders.reduce((sum, order) => sum + order.charged, 0)),
    subsidy: roundMoney(orders.reduce((sum, order) => sum + order.subsidy, 0)),
  }
}

function roundMoney(value: number) {
  return Math.round(value * 100) / 100
}
