import type { ReactNode } from "react"
import { useTranslation } from "react-i18next"

import ListItemCard from "@/components/list-item-card"
import StatusBadge from "@/components/status-badge"
import {
  CardAction,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
} from "@/components/ui/card"
import type { OrderStatus, ProviderOrder } from "@/types"

// La cantidad lleva el color del estado del pedido, igual que su badge.
const quantityStyles: Record<OrderStatus, string> = {
  pending: "text-blue-600 dark:text-blue-400",
  confirmed: "text-green-600 dark:text-green-400",
  cancelled: "text-red-600 dark:text-red-400",
  rejected: "text-red-600 dark:text-red-400",
}

interface ProviderOrderCardSummaryProps {
  order: ProviderOrder
  /** Online: un <Link> a la página del pedido. Offline: texto plano. */
  title: ReactNode
  /** Online: las acciones del proveedor. Offline: se omite. */
  footer?: ReactNode
}

export default function ProviderOrderCardSummary({
  order,
  title,
  footer,
}: ProviderOrderCardSummaryProps) {
  const { t } = useTranslation()

  const delivery = t(
    `pages.provider_orders.index.delivery_methods.${order.delivery_method}`,
  )

  return (
    <ListItemCard className="relative max-lg:gap-2.5 max-lg:shadow-none">
      <CardHeader>
        <CardDescription className="mt-1">{title}</CardDescription>
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
        <p className="text-muted-foreground text-sm lg:text-xs">
          {order.address
            ? `${t("pages.provider_orders.index.ship_to")} ${order.address}`
            : t("pages.provider_orders.index.no_address")}{" "}
          ({delivery})
        </p>
      </CardContent>

      {footer !== undefined && (
        <CardFooter className="empty:hidden max-lg:mt-1.5">{footer}</CardFooter>
      )}
    </ListItemCard>
  )
}

export function providerOrderCustomer(order: ProviderOrder) {
  return order.consumer_company
    ? `${order.consumer_name} - ${order.consumer_company}`
    : order.consumer_name
}
