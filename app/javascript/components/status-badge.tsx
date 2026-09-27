import { useTranslation } from "react-i18next"

import { Badge } from "@/components/ui/badge"
import { cn } from "@/lib/utils"
import type { OrderStatus, PaymentStatus } from "@/types"

// Tipar los mapas con los enums de Rails hace que agregar un estado rompa la
// compilación hasta que alguien decida cómo se ve.
const orderStyles: Record<OrderStatus, string> = {
  pending:
    "border-amber-200 bg-amber-50 text-amber-700 dark:border-amber-900 dark:bg-amber-950 dark:text-amber-300 [&>span]:bg-amber-500",
  confirmed:
    "border-green-200 bg-green-50 text-green-700 dark:border-green-900 dark:bg-green-950 dark:text-green-300 [&>span]:bg-green-500",
  cancelled:
    "border-red-200 bg-red-50 text-red-700 dark:border-red-900 dark:bg-red-950 dark:text-red-300 [&>span]:bg-red-500",
  rejected:
    "border-red-200 bg-red-50 text-red-700 dark:border-red-900 dark:bg-red-950 dark:text-red-300 [&>span]:bg-red-500",
}

const paymentStyles: Record<PaymentStatus, string> = {
  pending:
    "border-amber-200 bg-amber-50 text-amber-700 dark:border-amber-900 dark:bg-amber-950 dark:text-amber-300 [&>span]:bg-amber-500",
  submitted:
    "border-sky-200 bg-sky-50 text-sky-700 dark:border-sky-900 dark:bg-sky-950 dark:text-sky-300 [&>span]:bg-sky-500",
  approved:
    "border-green-200 bg-green-50 text-green-700 dark:border-green-900 dark:bg-green-950 dark:text-green-300 [&>span]:bg-green-500",
  rejected:
    "border-red-200 bg-red-50 text-red-700 dark:border-red-900 dark:bg-red-950 dark:text-red-300 [&>span]:bg-red-500",
}

interface StatusBadgeProps {
  status?: OrderStatus | PaymentStatus | null
  // pending y rejected existen en los dos enums, así que el valor solo no
  // alcanza para saber qué color y qué texto corresponden.
  kind?: "order" | "payment"
}

export default function StatusBadge({
  status,
  kind = "order",
}: StatusBadgeProps) {
  const { t } = useTranslation()

  if (!status) return null

  const className =
    kind === "payment"
      ? paymentStyles[status as PaymentStatus]
      : orderStyles[status as OrderStatus]

  const label =
    kind === "payment"
      ? t(`pages.provider_collections.statuses.${status}`)
      : t(`pages.orders.statuses.${status}`)

  return (
    <Badge
      variant="outline"
      data-status={status}
      className={cn("gap-1.5 px-2.5 py-1", className)}
    >
      <span className="size-1.5 rounded-full" />
      {label}
    </Badge>
  )
}
