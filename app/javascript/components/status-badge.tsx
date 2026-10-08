import { useTranslation } from "react-i18next"

import { Badge } from "@/components/ui/badge"
import { cn } from "@/lib/utils"
import type { InvoiceStatus, OrderStatus, PaymentStatus } from "@/types"

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

const providerOrderStyles: Record<OrderStatus, string> = {
  ...orderStyles,
  pending:
    "border-blue-200 bg-blue-50 text-blue-700 dark:border-blue-900 dark:bg-blue-950 dark:text-blue-300 [&>span]:bg-blue-500",
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

const invoiceStyles: Record<InvoiceStatus, string> = {
  pending:
    "border-sky-200 bg-sky-50 text-sky-700 dark:border-sky-900 dark:bg-sky-950 dark:text-sky-300 [&>span]:bg-sky-500",
  approved:
    "border-green-200 bg-green-50 text-green-700 dark:border-green-900 dark:bg-green-950 dark:text-green-300 [&>span]:bg-green-500",
  rejected:
    "border-red-200 bg-red-50 text-red-700 dark:border-red-900 dark:bg-red-950 dark:text-red-300 [&>span]:bg-red-500",
}

interface StatusBadgeProps {
  status?: OrderStatus | PaymentStatus | InvoiceStatus | null
  // pending y rejected existen en los dos enums, así que el valor solo no
  // alcanza para saber qué color y qué texto corresponden.
  kind?: "order" | "payment" | "invoice" | "provider_order"
}

export default function StatusBadge({
  status,
  kind = "order",
}: StatusBadgeProps) {
  const { t } = useTranslation()

  if (!status) return null

  const { className, label } = {
    order: {
      className: orderStyles[status as OrderStatus],
      label: t(`pages.orders.statuses.${status}`),
    },
    provider_order: {
      className: providerOrderStyles[status as OrderStatus],
      label: t(`pages.provider_orders.statuses.${status}`),
    },
    payment: {
      className: paymentStyles[status as PaymentStatus],
      label: t(`pages.provider_collections.statuses.${status}`),
    },
    invoice: {
      className: invoiceStyles[status as InvoiceStatus],
      label: t(`pages.provider_collections.invoice.statuses.${status}`),
    },
  }[kind]

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
