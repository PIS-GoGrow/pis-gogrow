import { Link } from "@inertiajs/react"
import { Check, X } from "lucide-react"
import { useMemo } from "react"

import { Button } from "@/components/ui/button"
import type { ConsumerDashboardIndex } from "@/types"

import { money } from "./formatters"

type Confirmation = NonNullable<ConsumerDashboardIndex["order_confirmation"]>

interface Props {
  confirmation: Confirmation
  homeUrl: string
}

export function OrderConfirmation({ confirmation, homeUrl }: Props) {
  const deliveries = useMemo(() => {
    return Object.values(
      confirmation.orders.reduce<
        Record<
          string,
          { address: string; label: string; items: Confirmation["orders"] }
        >
      >((groups, item) => {
        const key = `${item.provider_name}-${item.address}`

        groups[key] ??= {
          address: item.address,
          label: item.address_label,
          items: [],
        }
        groups[key].items.push(item)
        return groups
      }, {}),
    )
  }, [confirmation.orders])

  const deliveryDates = [
    ...new Set(confirmation.orders.map((item) => item.date)),
  ].map((date) =>
    new Date(`${date}T12:00:00`).toLocaleDateString("es-UY", {
      weekday: "long",
      day: "numeric",
      month: "long",
    }),
  )
  const primaryDelivery = deliveries[0]

  return (
    <div className="bg-background border-border text-foreground relative mx-auto flex min-h-screen max-w-3xl flex-col px-6 pt-6 pb-8 md:my-8 md:min-h-0 md:rounded-2xl md:border md:p-8">
      <Button
        asChild
        type="button"
        variant="ghost"
        size="icon"
        className="absolute top-5 right-5"
      >
        <Link href={homeUrl} preserveState={false} aria-label="Cerrar">
          <X aria-hidden="true" className="size-5" />
        </Link>
      </Button>
      <div className="bg-primary text-primary-foreground mx-auto flex size-20 items-center justify-center rounded-full">
        <Check aria-hidden="true" className="size-10" strokeWidth={2.5} />
      </div>
      <h1 className="mt-7 text-center text-2xl font-bold">¡Pedido recibido!</h1>
      <p className="text-muted-foreground mt-2 text-center text-base leading-6">
        Te notificaremos cuando el proveedor confirme tu pedido.
      </p>

      <section className="border-border bg-muted mt-7 rounded-lg border p-4 text-sm">
        <p className="text-muted-foreground">Entrega</p>
        <p className="mt-1 font-semibold capitalize">{deliveryDates[0]}</p>
        {primaryDelivery && (
          <p className="mt-1 font-medium">
            {primaryDelivery.label} | {primaryDelivery.address}
          </p>
        )}

        <div className="border-border mt-4 space-y-4 border-t pt-4">
          {deliveries.map((delivery) => (
            <section key={`${delivery.label}-${delivery.address}`}>
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
          <p className="mt-1 text-lg font-bold">{money(confirmation.total)}</p>
        </div>
      </section>

      <Button
        type="button"
        className="bg-primary text-primary-foreground hover:bg-primary/90 hover:text-primary-foreground mt-auto h-12 w-full"
      >
        Ir a Mis pedidos
      </Button>
    </div>
  )
}
