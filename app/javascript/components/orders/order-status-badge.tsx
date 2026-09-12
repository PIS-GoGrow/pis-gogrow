import { useTranslation } from "react-i18next"

import { Badge } from "@/components/ui/badge"
import type { OrderStatus } from "@/types"

// Tipar el mapa con OrderStatus hace que agregar un estado al enum de Rails
// rompa la compilación hasta que alguien decida cómo se ve.
const statusStyles: Record<OrderStatus, string> = {
  pending:
    "bg-amber-50 text-amber-700 dark:bg-amber-950 dark:text-amber-300 [&>span]:bg-amber-500",
  confirmed:
    "bg-green-50 text-green-700 dark:bg-green-950 dark:text-green-300 [&>span]:bg-green-500",
  cancelled:
    "bg-red-50 text-red-700 dark:bg-red-950 dark:text-red-300 [&>span]:bg-red-500",
  rejected:
    "bg-red-50 text-red-700 dark:bg-red-950 dark:text-red-300 [&>span]:bg-red-500",
}

interface OrderStatusBadgeProps {
  status: OrderStatus
}

export default function OrderStatusBadge({ status }: OrderStatusBadgeProps) {
  const { t } = useTranslation()

  return (
    <Badge className={`gap-1.5 px-2.5 py-1 ${statusStyles[status]}`}>
      <span className="size-1.5 rounded-full" />
      {t(`pages.orders.statuses.${status}`)}
    </Badge>
  )
}
