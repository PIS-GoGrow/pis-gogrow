import { Link } from "@inertiajs/react"
import { Check, X } from "lucide-react"
import { useMemo } from "react"
import { useTranslation } from "react-i18next"

import { BottomAction, MobileCard } from "@/components/consumer/mobile-card"
import { Button } from "@/components/ui/button"
import AppLayout from "@/layouts/app-layout"
import { consumerDashboard, consumerOrders } from "@/routes"
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
      breadcrumbs={[
        {
          title: t("pages.consumer_dashboard.confirmation.menu"),
          href: consumerDashboard.index().url,
        },
      ]}
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
          className="ml-auto size-9 rounded-[10px]"
        >
          <Link
            href={consumerDashboard.index()}
            preserveState={false}
            aria-label={t(
              "pages.consumer_dashboard.confirmation.close",
              "Cerrar",
            )}
            prefetch
          >
            <X aria-hidden="true" className="size-4" />
          </Link>
        </Button>

        <div className="mx-auto mt-4 flex size-20 items-center justify-center rounded-full bg-[#171717] text-[#fafafa] dark:bg-zinc-100 dark:text-zinc-900">
          <Check aria-hidden="true" className="size-10" strokeWidth={2.5} />
        </div>

        <h1 className="mt-4 text-center text-2xl font-bold">
          {t("pages.consumer_dashboard.confirmation.title")}
        </h1>
        <p className="text-muted-foreground mt-2 text-center text-base leading-6">
          {t("pages.consumer_dashboard.confirmation.subtitle")}
        </p>

        <div className="border-border bg-muted mt-6 rounded-lg border p-4 text-sm">
          <div>
            <p className="text-muted-foreground font-medium">
              {t("pages.consumer_dashboard.confirmation.delivery")}
            </p>
            <p className="text-foreground mt-1 text-base font-medium capitalize">
              {deliveryDates[0]}
            </p>
            {primaryDelivery && (
              <p className="text-foreground mt-1 text-base font-medium">
                {t(
                  `pages.orders.delivery_methods.${primaryDelivery.deliveryMethod}`,
                )}{" "}
                | {primaryDelivery.address}
              </p>
            )}
          </div>

          <div className="border-border mt-3 space-y-3 border-t pt-3">
            {deliveries.map((delivery, index) => (
              <section
                key={`${delivery.items[0]?.provider_name}-${delivery.deliveryMethod}-${delivery.address}`}
                className={index > 0 ? "border-border border-t pt-3" : ""}
              >
                <p className="text-muted-foreground font-medium">
                  {delivery.items[0]?.provider_name}
                </p>
                <div className="mt-2 space-y-2">
                  {delivery.items.map((item) => (
                    <div
                      key={item.id}
                      className="flex items-center justify-between text-base"
                    >
                      <span className="text-foreground font-medium">
                        <span>{item.name}</span>
                        <span>
                          {" "}
                          | {money(item.discounted_price / item.quantity)}
                        </span>
                      </span>
                      <span className="text-foreground font-semibold">
                        x{item.quantity}
                      </span>
                    </div>
                  ))}
                </div>
              </section>
            ))}
          </div>

          <div className="border-border mt-3 border-t pt-3">
            <p className="text-muted-foreground font-medium">
              {t("pages.consumer_dashboard.confirmation.amount_to_pay")}
            </p>
            <p className="text-foreground mt-1 text-base font-medium">
              {money(total)}
            </p>
          </div>
        </div>

        <BottomAction>
          <Button
            className="h-12 w-full rounded-[10px] text-base font-medium"
            asChild
          >
            <Link href={consumerOrders.index()} prefetch>
              {t("pages.consumer_dashboard.confirmation.view_orders")}
            </Link>
          </Button>
        </BottomAction>
      </MobileCard>
    </AppLayout>
  )
}
