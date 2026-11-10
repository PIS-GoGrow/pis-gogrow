import { Fragment, type ReactNode } from "react"
import { useEffect, useState } from "react"
import { useTranslation } from "react-i18next"

import OrderCardReduced from "@/components/orders/order-card-reduced"
import ProviderOrderCardSummary, {
  providerOrderCustomer,
} from "@/components/orders/provider-order-card-summary"
import { Button } from "@/components/ui/button"
import { formatLongDate } from "@/lib/dates"
import { db } from "@/lib/offline-db"
import type { ConsumerOrdersIndex, ProviderOrdersIndex } from "@/types"

type CachedOrders =
  | {
      role: "consumer"
      upcoming: ConsumerOrdersIndex["upcoming_orders"]
      saved_at: number
    }
  | {
      role: "provider"
      upcoming: ProviderOrdersIndex["upcoming_orders"]
      saved_at: number
    }

export default function OfflineApp() {
  const { t } = useTranslation()
  const [cached, setCached] = useState<CachedOrders | null>(null)

  useEffect(() => {
    async function loadOrders() {
      const provider = await db.provider_orders.get(1)

      if (provider?.upcoming_orders && provider.upcoming_orders.length > 0) {
        setCached({
          role: "provider",
          upcoming: provider.upcoming_orders,
          saved_at: provider.saved_at,
        })
        return
      }

      const consumer = await db.consumer_orders.get(1)

      if (consumer) {
        setCached({
          role: "consumer",
          upcoming: consumer.upcoming_orders ?? [],
          saved_at: consumer.saved_at,
        })
      }
    }

    void loadOrders()
  }, [])

  const groupByDate = <T extends { date?: string | null }>(orders: T[]) =>
    orders.reduce<{ date: string | null; orders: T[] }[]>((groups, order) => {
      const date = order.date ?? null
      const group = groups.find((candidate) => candidate.date === date)

      if (group) {
        group.orders.push(order)
      } else {
        groups.push({ date, orders: [order] })
      }

      return groups
    }, [])

  const renderGroups = <
    T extends { id: number | string; date?: string | null },
  >(
    orders: T[],
    renderOrder: (order: T) => ReactNode,
  ) =>
    groupByDate(orders).map((group) => (
      <section key={group.date ?? "undated"} className="grid gap-2">
        <h2 className="text-muted-foreground text-sm">
          {group.date
            ? formatLongDate(group.date, "es")
            : t("pages.orders.index.no_date")}
        </h2>

        {group.orders.map((order) => (
          <Fragment key={order.id}>{renderOrder(order)}</Fragment>
        ))}
      </section>
    ))

  return (
    <div className="flex min-h-screen flex-col items-center justify-center gap-4 p-4">
      <h1 className="text-3xl font-bold">Estás sin conexión</h1>

      <Button onClick={() => location.reload()}>Reintentar</Button>

      {cached?.upcoming && cached?.upcoming.length > 0 && (
        <section className="w-full max-w-xl">
          <h2 className="mb-2 text-lg font-semibold">
            {cached.role === "provider"
              ? "Pedidos pendientes recibidos:"
              : "Pedidos realizados:"}
          </h2>

          <p>
            {cached.role === "provider"
              ? "Estos son los pedidos que recibiste, según la última vez que estuviste en línea. Sus estados pueden haber cambiado."
              : "Estos son los pedidos que hiciste, según la última vez que estuviste en línea. Sus estados pueden haber cambiado."}
          </p>

          <p className="text-muted-foreground mb-4 text-sm">
            Última actualización:{" "}
            {new Date(cached.saved_at).toLocaleString("es-UY")}
          </p>

          <div className="space-y-2">
            {cached.role === "consumer"
              ? renderGroups(cached.upcoming, (order) => (
                  <OrderCardReduced
                    order={order}
                    section="upcoming"
                    clickable
                    title={order.menu_name ?? t("pages.orders.index.no_menu")}
                  />
                ))
              : renderGroups(cached.upcoming, (order) => (
                  <ProviderOrderCardSummary
                    order={order}
                    title={providerOrderCustomer(order)}
                  />
                ))}
          </div>
        </section>
      )}
    </div>
  )
}
