import { Badge } from "@/components/ui/badge"
import { cn } from "@/lib/utils"

export type OrderStatus = "pending" | "confirmed" | "delivered" | "cancelled"

const statuses: Record<OrderStatus, { label: string; className: string }> = {
  pending: {
    label: "Pendiente",
    className:
      "border-amber-300 bg-amber-50 text-amber-800 dark:border-amber-800 dark:bg-amber-950 dark:text-amber-200",
  },
  confirmed: {
    label: "Confirmado",
    className:
      "border-blue-300 bg-blue-50 text-blue-800 dark:border-blue-800 dark:bg-blue-950 dark:text-blue-200",
  },
  delivered: {
    label: "Entregado",
    className:
      "border-green-300 bg-green-50 text-green-800 dark:border-green-800 dark:bg-green-950 dark:text-green-200",
  },
  cancelled: {
    label: "Cancelado",
    className:
      "border-red-300 bg-red-50 text-red-800 dark:border-red-800 dark:bg-red-950 dark:text-red-200",
  },
}

interface OrderStatusBadgeProps {
  status: OrderStatus
  className?: string
}

export default function OrderStatusBadge({
  status,
  className,
}: OrderStatusBadgeProps) {
  const { label, className: statusClassName } = statuses[status]

  return (
    <Badge
      variant="outline"
      data-status={status}
      className={cn(statusClassName, className)}
    >
      {label}
    </Badge>
  )
}
