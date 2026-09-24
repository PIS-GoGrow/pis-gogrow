import { Link } from "@inertiajs/react"
import { Check, X } from "lucide-react"
import { useMemo } from "react"
import { useTranslation } from "react-i18next"

import { BottomAction, MobileCard } from "@/components/consumer/mobile-card"
import { Button } from "@/components/ui/button"
import AppLayout from "@/layouts/app-layout"
import { consumerDashboard, orders as ordersRoutes } from "@/routes"
import type { ConsumerDashboardConfirmation } from "@/types"

import { money } from "./formatters"

type Confirmation = ConsumerDashboardConfirmation

export default function OrderConfirmation({ total, orders }: Confirmation) {
  const { t } = useTranslation()

  const deliveries = useMemo(() => {
    return Object.values(
      orders.reduce<
        Record<
          string,
          {
            address: string
            deliveryMethod: string
            items: Confirmation["orders"]
          }
        >
      >((groups, item) => {
        const key = `${item.provider_name}-${item.delivery_method}-${item.address}`

        groups[key] ??= {
          address: item.address,
          deliveryMethod: item.delivery_method,
          items: [],
        }
        groups[key].items.push(item)
        return groups
      }, {}),
    )
  }, [orders])

  const deliveryDates = [...new Set(orders.map((item) => item.date))].map(
    (date) =>
      new Date(`${date}T12:00:00`).toLocaleDateString("es-UY", {
        weekday: "long",
        day: "numeric",
        month: "long",
      }),
  )

  const primaryDelivery = deliveries[0]
  return (
    <AppLayout
      breadcrumbs={[{ title: "Menú", href: consumerDashboard.index().url }]}
    >
      <style>
        {
          '@media (max-width: 767px) { [data-slot="sidebar-inset"] > header { display: none; } }'
        }
      </style>
      <MobileCard className="grid">
        <Button
          asChild
          type="button"
          variant="ghost"
          size="icon"
          className="ml-auto"
        >
          <Link
            href={consumerDashboard.index()}
            preserveState={false}
            aria-label="Cerrar"
            prefetch
          >
            <X aria-hidden="true" className="size-5" />
          </Link>
        </Button>

        <div className="bg-primary text-primary-foreground mx-auto flex size-20 items-center justify-center rounded-full">
          <Check aria-hidden="true" className="size-10" strokeWidth={2.5} />
        </div>

        <h1 className="mt-3 text-center text-2xl font-bold">
          ¡Pedido recibido!
        </h1>
        <p className="text-muted-foreground text-center text-base leading-6">
          Te notificaremos cuando el proveedor confirme tu pedido.
        </p>

        <div className="border-border bg-muted mt-5 rounded-lg border p-4 text-sm">
          <p className="text-muted-foreground">Entrega</p>
          <p className="mt-1 font-semibold capitalize">{deliveryDates[0]}</p>
          {primaryDelivery && (
            <p className="mt-1 font-medium">
              {t(
                `pages.orders.delivery_methods.${primaryDelivery.deliveryMethod}`,
              )}{" "}
              | {primaryDelivery.address}
            </p>
          )}

          <div className="border-border mt-4 space-y-4 border-t pt-4">
            {deliveries.map((delivery) => (
              <section
                key={`${delivery.items[0]?.provider_name}-${delivery.deliveryMethod}-${delivery.address}`}
              >
                <p className="text-muted-foreground">
                  {delivery.items[0]?.provider_name}
                </p>
                <div className="mt-2 space-y-2">
                  {delivery.items.map((item) => (
                    <div
                      key={item.id}
                      className="flex items-baseline justify-between gap-3"
                    >
                      <p className="min-w-0">
                        <span className="font-medium">{item.name}</span>
                        <span className="text-muted-foreground">
                          {" "}
                          | {money(item.discounted_price / item.quantity)}
                        </span>
                      </p>
                      <span className="shrink-0 font-semibold">
                        x{item.quantity}
                      </span>
                    </div>
                  ))}
                </div>
              </section>
            ))}
          </div>

          <div className="border-border mt-4 border-t pt-4">
            <p className="text-muted-foreground">Monto a pagar</p>
            <p className="mt-1 text-lg font-bold">{money(total)}</p>
          </div>
        </div>

        <BottomAction>
          <Button className="h-12 w-full" asChild>
            <Link href={ordersRoutes.index()} prefetch>
              Ver mis pedidos
            </Link>
          </Button>
        </BottomAction>
      </MobileCard>
    </AppLayout>
  )
}
