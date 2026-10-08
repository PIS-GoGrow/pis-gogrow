import { Link } from "@inertiajs/react"
import { useTranslation } from "react-i18next"

import ListItemCard from "@/components/list-item-card"
import ProviderOrderActions from "@/components/orders/provider-order-actions"
import StatusBadge from "@/components/status-badge"
import {
  CardAction,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
} from "@/components/ui/card"
import { providerOrders } from "@/routes"
import type { OrderStatus, ProviderOrder } from "@/types"

// La cantidad lleva el color del estado del pedido, igual que su badge.
const quantityStyles: Record<OrderStatus, string> = {
  pending: "text-blue-600 dark:text-blue-400",
  confirmed: "text-green-600 dark:text-green-400",
  cancelled: "text-red-600 dark:text-red-400",
  rejected: "text-red-600 dark:text-red-400",
}

interface ProviderOrderCardProps {
  order: ProviderOrder
}

export default function ProviderOrderCard({ order }: ProviderOrderCardProps) {
  const { t } = useTranslation()

  const customer = order.consumer_company
    ? `${order.consumer_name} - ${order.consumer_company}`
    : order.consumer_name
  const delivery = t(
    `pages.provider_orders.index.delivery_methods.${order.delivery_method}`,
  )

  return (
    <ListItemCard className="relative">
      <CardHeader>
        <CardDescription>
          <Link
            href={providerOrders.show(order.id).url}
            className="after:absolute after:inset-0 hover:underline"
          >
            {customer}
          </Link>
          <span className="block text-xs">
            {t("pages.provider_orders.index.code", { id: order.id })}
          </span>
        </CardDescription>
        <CardAction>
          <StatusBadge status={order.status} kind="provider_order" />
        </CardAction>
      </CardHeader>

      <CardContent className="grid gap-1">
        <p className="font-semibold">
          {order.menu_name}{" "}
          <span className={quantityStyles[order.status]}>
            {t("pages.provider_orders.index.quantity", {
              count: order.amount ?? 0,
            })}
          </span>
        </p>
        <p className="text-muted-foreground text-xs">
          {order.address
            ? `${t("pages.provider_orders.index.ship_to")} ${order.address}`
            : t("pages.provider_orders.index.no_address")}{" "}
          ({delivery})
        </p>
      </CardContent>

      <CardFooter>
        <ProviderOrderActions
          order={order}
          keepVisible
          className="relative w-full"
        />
      </CardFooter>
    </ListItemCard>
  )
}
