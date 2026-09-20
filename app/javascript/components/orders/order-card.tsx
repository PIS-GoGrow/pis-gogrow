import { Link } from "@inertiajs/react"
import { X } from "lucide-react"
import { useTranslation } from "react-i18next"

import CancelOrderSheet from "@/components/orders/cancel-order-sheet"
import StatusBadge from "@/components/status-badge"
import { Button } from "@/components/ui/button"
import {
  Card,
  CardAction,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { useFormatters } from "@/hooks/use-formatters"
import { orders as ordersRoutes } from "@/routes"
import type { Order } from "@/types"

interface OrderCardProps {
  order: Order
  section: "upcoming" | "history"
}

export default function OrderCard({ order, section }: OrderCardProps) {
  const { t } = useTranslation()
  const { formatMoney } = useFormatters()

  // El empleado paga el precio ya subsidiado; el base se muestra al lado solo
  // cuando el subsidio efectivamente lo bajó.
  const charged = order.discounted_price ?? order.price
  const basePrice =
    order.price != null && order.price !== charged ? order.price : null

  return (
    <Card className="hover:bg-accent/40 focus-within:ring-ring/50 relative gap-2 py-4 transition-colors focus-within:ring-[3px]">
      <CardHeader className="gap-1 px-4">
        <CardDescription>
          {order.provider_name ?? t("pages.orders.index.no_provider")}
        </CardDescription>
        <CardTitle>
          {/* El ::after estirado hace clickeable toda la tarjeta sin duplicar
              enlaces ni anidar el badge dentro del link. */}
          <Link
            href={ordersRoutes.show(order.id).url}
            className="after:absolute after:inset-0 hover:underline"
          >
            {order.menu_name ?? t("pages.orders.index.no_menu")}
          </Link>{" "}
          <span className="text-muted-foreground font-normal">
            {t("pages.orders.index.quantity", { count: order.amount ?? 0 })}
          </span>
        </CardTitle>
        <CardAction>
          <StatusBadge status={order.status} />
        </CardAction>
      </CardHeader>

      <CardContent className="flex items-baseline justify-between gap-3 px-4">
        <p className="text-muted-foreground text-sm">
          {order.address
            ? t(`pages.orders.index.${section}_address`, {
                address: order.address,
                delivery_method: t(
                  `pages.orders.delivery_methods.${order.delivery_method}`,
                ),
              })
            : t("pages.orders.index.no_address")}
        </p>

        <p className="shrink-0 text-sm font-medium">
          {charged == null ? (
            t("pages.orders.index.no_price")
          ) : (
            <>
              {basePrice != null && (
                <span
                  className="text-muted-foreground me-1.5 font-normal line-through"
                  aria-label={t("pages.orders.index.base_price", {
                    amount: formatMoney(basePrice),
                  })}
                >
                  {formatMoney(basePrice)}
                </span>
              )}
              {formatMoney(charged)}
            </>
          )}
        </p>
      </CardContent>

      {/* El ::after de la tarjeta cubre todo para hacerla clickeable, así que
          las acciones necesitan quedar por encima para poder tocarlas. */}
      {section === "upcoming" && (
        <CardFooter className="relative z-10 flex-col items-stretch gap-2 px-4">
          {order.cancellable ? (
            <CancelOrderSheet order={order} />
          ) : (
            <>
              <Button type="button" variant="outline" size="sm" disabled>
                <X aria-hidden="true" />
                {t("pages.orders.index.cancel")}
              </Button>
              <p className="text-muted-foreground text-xs">
                {t(
                  `pages.orders.index.cannot_cancel.${order.cancellation_block_reason}`,
                )}
              </p>
            </>
          )}
        </CardFooter>
      )}
    </Card>
  )
}
