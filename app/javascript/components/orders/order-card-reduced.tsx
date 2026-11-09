// components/orders/order-card-summary.tsx
import type { ReactNode } from "react"
import { useTranslation } from "react-i18next"

import StatusBadge from "@/components/status-badge"
import {
  Card,
  CardAction,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { cn } from "@/lib/utils"
import type { Order } from "@/types"

interface Props {
  order: Order
  section: "upcoming" | "history"
  /** Nombre del menú: un <Link> online, texto plano offline. */
  title: ReactNode
  footer?: ReactNode
  clickable?: boolean
}

export default function OrderCardReduced({
  order,
  section,
  title,
  footer,
  clickable = false,
}: Props) {
  const { t } = useTranslation()
  const notReceived =
    order.status === "cancelled" || order.status === "rejected"
  const addressKey = notReceived ? "cancelled_address" : `${section}_address`

  return (
    <Card
      className={cn(
        "relative gap-2 py-4",
        clickable &&
          "hover:bg-accent/40 focus-within:ring-ring/50 transition-colors focus-within:ring-[3px]",
      )}
    >
      <CardHeader className="gap-1 px-4">
        <CardDescription>
          {order.provider_name ?? t("pages.orders.index.no_provider")}
        </CardDescription>
        <CardTitle>
          {title}{" "}
          <span className="text-muted-foreground font-normal">
            {t("pages.orders.index.quantity", { count: order.amount ?? 0 })}
          </span>
        </CardTitle>
        <CardAction>
          <StatusBadge
            status={order.status}
            label={
              section === "history" && order.status === "confirmed"
                ? t("pages.orders.statuses.delivered")
                : undefined
            }
          />
        </CardAction>
      </CardHeader>

      <CardContent className="px-4">
        <p className="text-muted-foreground text-sm">
          {order.address
            ? t(`pages.orders.index.${addressKey}`, {
                address: order.address,
                delivery_method: t(
                  `pages.orders.delivery_methods.${order.delivery_method}`,
                ),
              })
            : t("pages.orders.index.no_address")}
        </p>
      </CardContent>

      {footer && <CardFooter className="relative">{footer}</CardFooter>}
    </Card>
  )
}
