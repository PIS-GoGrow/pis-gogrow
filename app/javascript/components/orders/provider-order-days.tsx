import { ShoppingBasket01Icon } from "@hugeicons/core-free-icons"
import { HugeiconsIcon } from "@hugeicons/react"
import { ChevronDown } from "lucide-react"
import { type ReactNode, useState } from "react"
import { useTranslation } from "react-i18next"

import ProviderOrderCard from "@/components/orders/provider-order-card"
import type { ProviderOrderDecision } from "@/components/orders/provider-order-decided-sheet"
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible"
import {
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyMedia,
  EmptyTitle,
} from "@/components/ui/empty"
import { useFormatters } from "@/hooks/use-formatters"
import {
  type OrderFilters,
  filterOrders,
  groupByDate,
  initialDate,
  ordersColumns,
  searchableText,
  summarize,
} from "@/lib/provider-orders"
import { cn } from "@/lib/utils"
import type { ProviderOrder } from "@/types"

interface ProviderOrderDaysProps {
  orders: ProviderOrder[]
  today: string
  filters: OrderFilters
  footer?: ReactNode
  onDecided: (decision: ProviderOrderDecision) => void
}

export default function ProviderOrderDays({
  orders,
  today,
  filters,
  footer,
  onDecided,
}: ProviderOrderDaysProps) {
  const { t } = useTranslation()
  const { formatMoney, formatShortDate } = useFormatters()
  // undefined: el usuario todavía no eligió; null: cerró el día abierto.
  const [selected, setSelected] = useState<string | null | undefined>(undefined)

  const filtered = filterOrders(orders, filters, (order) =>
    searchableText(order, t),
  )
  const days = groupByDate(filtered)

  if (days.length === 0) {
    const noOrders = orders.length === 0

    return (
      <Empty
        className={cn(
          "min-h-[50svh]",
          noOrders && "max-lg:min-h-[calc(100svh-15rem)]",
        )}
      >
        <EmptyHeader>
          <EmptyMedia variant="icon" className="size-10">
            <HugeiconsIcon
              icon={ShoppingBasket01Icon}
              size={20}
              className="size-5"
              aria-hidden="true"
            />
          </EmptyMedia>
          <EmptyTitle className="text-base">
            {t(
              `pages.provider_orders.index.${noOrders ? "no_orders_title" : "empty_title"}`,
            )}
          </EmptyTitle>
          <EmptyDescription className="text-wrap">
            {t(
              `pages.provider_orders.index.${noOrders ? "no_orders_description" : "empty_filtered_description"}`,
            )}
          </EmptyDescription>
        </EmptyHeader>
      </Empty>
    )
  }

  const activeDate =
    selected === null
      ? null
      : days.some((day) => day.date === selected)
        ? selected
        : initialDate(days, today)

  // En escritorio el día elegido queda fijo: el panel de la derecha no se vacía.
  function handleOpenChange(date: string, open: boolean) {
    if (open) setSelected(date)
    else if (!window.matchMedia("(min-width: 1024px)").matches)
      setSelected(null)
  }

  return (
    <div
      className={cn("grid gap-3 lg:items-start", ordersColumns)}
      style={{ gridTemplateRows: `repeat(${days.length}, auto) 1fr` }}
    >
      {days.map((day) => {
        const { meals, total } = summarize(day.orders)

        return (
          <Collapsible
            key={day.date}
            open={day.date === activeDate}
            onOpenChange={(open) => handleOpenChange(day.date, open)}
            className="flex flex-col rounded-lg border lg:contents"
          >
            <CollapsibleTrigger className="group lg:data-[state=open]:bg-muted flex w-full items-center justify-between gap-2 p-3 text-left text-sm font-medium lg:col-start-1 lg:rounded-lg lg:border">
              {t("pages.provider_orders.index.day_summary", {
                date: formatShortDate(day.date),
                meals,
                amount: formatMoney(total),
              })}
              <ChevronDown
                className="text-muted-foreground size-4 shrink-0 transition-transform group-data-[state=open]:rotate-180 lg:hidden"
                aria-hidden="true"
              />
            </CollapsibleTrigger>

            <CollapsibleContent
              className="lg:before:bg-border @container grid gap-3 px-3 pb-3 lg:relative lg:col-start-2 lg:self-stretch lg:px-0 lg:pb-0 lg:before:absolute lg:before:inset-y-0 lg:before:-left-6 lg:before:w-px"
              style={{ gridRow: "1 / -1" }}
            >
              <div className="grid gap-3 @2xl:grid-cols-2">
                {day.orders.map((order) => (
                  <ProviderOrderCard
                    key={order.id}
                    order={order}
                    onDecided={onDecided}
                  />
                ))}
              </div>
            </CollapsibleContent>
          </Collapsible>
        )
      })}

      {footer && <div className="mt-3 lg:col-start-1">{footer}</div>}
    </div>
  )
}
