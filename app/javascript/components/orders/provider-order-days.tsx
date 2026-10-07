import { ChevronDown, Package } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import ProviderOrderCard from "@/components/orders/provider-order-card"
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
  formatDayDate,
  groupByDate,
  hasActiveFilters,
  initialDate,
  ordersColumns,
  summarize,
  withToday,
} from "@/lib/provider-orders"
import { cn } from "@/lib/utils"
import type { ProviderOrder } from "@/types"

interface ProviderOrderDaysProps {
  orders: ProviderOrder[]
  today: string
  period: "upcoming" | "history"
  filters: OrderFilters
}

export default function ProviderOrderDays({
  orders,
  today,
  period,
  filters,
}: ProviderOrderDaysProps) {
  const { t } = useTranslation()
  const { formatMoneyShort } = useFormatters()
  // undefined: el usuario todavía no eligió; null: cerró el día abierto.
  const [selected, setSelected] = useState<string | null | undefined>(undefined)

  const filtered = filterOrders(orders, filters, (order) => [
    order.consumer_name,
    order.consumer_company,
    order.menu_name,
    order.address,
    order.notes,
    t("pages.provider_orders.index.code", { id: order.id }),
    t(`pages.provider_orders.statuses.${order.status}`),
    t(`pages.provider_orders.index.delivery_methods.${order.delivery_method}`),
  ])
  const grouped = groupByDate(filtered)
  // Sin filtros, hoy siempre aparece: es el valor inicial de la pantalla.
  const days =
    period === "upcoming" && !hasActiveFilters(filters)
      ? withToday(grouped, today)
      : grouped

  if (days.length === 0) {
    const description = hasActiveFilters(filters)
      ? "empty_filtered_description"
      : period === "upcoming"
        ? "empty_description"
        : "empty_history_description"

    return (
      <Empty className="border">
        <EmptyHeader>
          <EmptyMedia variant="icon">
            <Package aria-hidden="true" />
          </EmptyMedia>
          <EmptyTitle>
            {t("pages.provider_orders.index.empty_title")}
          </EmptyTitle>
          <EmptyDescription>
            {t(`pages.provider_orders.index.${description}`)}
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
                date: formatDayDate(day.date),
                meals,
                amount: formatMoneyShort(total),
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
              {day.orders.length === 0 ? (
                <p className="text-muted-foreground text-sm">
                  {t("pages.provider_orders.index.empty_title")}
                </p>
              ) : (
                <div className="grid gap-3 @2xl:grid-cols-2">
                  {day.orders.map((order) => (
                    <ProviderOrderCard key={order.id} order={order} />
                  ))}
                </div>
              )}
            </CollapsibleContent>
          </Collapsible>
        )
      })}
    </div>
  )
}
