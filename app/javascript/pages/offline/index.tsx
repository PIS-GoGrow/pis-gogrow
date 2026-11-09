import { Button } from "@/components/ui/button"

import { formatLongDate } from "@/lib/dates"

import { useEffect, useState } from "react"
import { useTranslation } from "react-i18next"
import OrderCardReduced from "@/components/orders/order-card-reduced"
import ProviderOrderCardSummary, {
  providerOrderCustomer,
} from "@/components/orders/provider-order-card-summary"
import { db } from "@/lib/offline-db"

import type { ConsumerOrdersIndex, ProviderOrdersIndex } from "@/types"

type CachedOrders = {
  upcoming_orders?:
    | ConsumerOrdersIndex["upcoming_orders"]
    | ProviderOrdersIndex["upcoming_orders"]
  saved_at: number
}

export default function OfflineApp() {
  const { t } = useTranslation()
  const [cached, setCached] = useState<CachedOrders | null>(null)
  const [role, setRole] = useState<"consumer" | "provider" | null>(null)

  useEffect(() => {
    async function loadOrders() {
      const provider = await db.provider_orders.get(1)

      if (
        provider &&
        provider?.upcoming_orders &&
        provider?.upcoming_orders?.length > 0
      ) {
        setCached(provider)
        setRole("provider")
        return
      }

      const consumer = await db.consumer_orders.get(1)

      if (consumer) {
        setCached(consumer)
        setRole("consumer")
      }
    }

    loadOrders()
  }, [])

  const orders = cached?.upcoming_orders

  const groupByDate = (
    orders:
      | ConsumerOrdersIndex["upcoming_orders"]
      | ProviderOrdersIndex["upcoming_orders"],
  ) =>
    orders.reduce<{ date: string | null; orders: Order[] }[]>(
      (groups, order) => {
        const date = order.date ?? null
        const group = groups.find((candidate) => candidate.date === date)

        if (group) {
          group.orders.push(order)
        } else {
          groups.push({ date, orders: [order] })
        }

        return groups
      },
      [],
    )

  const renderGroups = (
    orders:
      | ConsumerOrdersIndex["upcoming_orders"]
      | ProviderOrdersIndex["upcoming_orders"],
  ) =>
    groupByDate(orders).map((group) => (
      <section key={group.date ?? "undated"} className="grid gap-2">
        <h2 className="text-muted-foreground text-sm">
          {group.date
            ? formatLongDate(group.date, "es")
            : t("pages.orders.index.no_date")}
        </h2>

        {role === "consumer"
          ? group.orders.map((order) => (
              <OrderCardReduced
                key={order.id}
                order={order}
                section={"upcoming"}
                clickable
                title={order.menu_name ?? t("pages.orders.index.no_menu")}
              />
            ))
          : group.orders.map((order) => (
              <ProviderOrderCardSummary
                key={order.id}
                order={order}
                title={providerOrderCustomer(order)}
              />
            ))}
      </section>
    ))

  return (
    <div className="flex min-h-screen flex-col items-center justify-center gap-4 p-4">
      <h1 className="text-3xl font-bold">Estás sin conexión</h1>

      <Button onClick={() => location.reload()}>Reintentar</Button>

      {orders && orders.length > 0 && (
        <section className="w-full max-w-xl">
          <h2 className="mb-2 text-lg font-semibold">
            {role === "provider"
              ? "Pedidos pendientes recibidos:"
              : "Pedidos realizados:"}
          </h2>

          <p>
            {role === "provider"
              ? "Estos son los pedidos que recibiste, según la última vez que estuviste en línea."
              : "Estos son los pedidos que hiciste, según la última vez que estuviste en línea."}
          </p>

          <p className="text-muted-foreground mb-4 text-sm">
            Última actualización:{" "}
            {new Date(cached!.saved_at).toLocaleString("es-UY")}
          </p>

          <div className="space-y-2">{renderGroups(orders)}</div>
        </section>
      )}
    </div>
  )
}
