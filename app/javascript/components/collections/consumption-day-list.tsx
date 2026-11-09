import { ChevronDown } from "lucide-react"
import type { ReactNode } from "react"
import { useTranslation } from "react-i18next"

import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible"

interface ConsumptionDay<Order> {
  date: string
  orders: Order[]
}

interface ConsumptionDayListProps<Order> {
  days: ConsumptionDay<Order>[]
  mealsOf: (order: Order) => number
  amountOf: (order: Order) => number
  formatAmount: (amount: number) => string
  emptyLabel: string
  children: (orders: Order[]) => ReactNode
}

const page = "pages.provider_collections.index"

export default function ConsumptionDayList<Order>({
  days,
  mealsOf,
  amountOf,
  formatAmount,
  emptyLabel,
  children,
}: ConsumptionDayListProps<Order>) {
  const { t } = useTranslation()

  if (days.length === 0) {
    return (
      <p className="text-muted-foreground py-8 text-center text-sm">
        {emptyLabel}
      </p>
    )
  }

  const total = (orders: Order[], value: (order: Order) => number) =>
    orders.reduce((sum, order) => sum + value(order), 0)

  return (
    <div className="divide-y rounded-xl border px-4">
      {days.map((day, index) => (
        <Collapsible key={day.date} defaultOpen={index === 0}>
          <CollapsibleTrigger asChild>
            <button
              type="button"
              className="group flex w-full items-center justify-between gap-3 py-4 text-left text-sm font-medium"
            >
              <span>
                {t(`${page}.consumption_day`, { date: day.date })} |{" "}
                {t(`${page}.consumption_meals`, {
                  count: total(day.orders, mealsOf),
                })}{" "}
                |{" "}
                {t(`${page}.consumption_amount`, {
                  amount: formatAmount(total(day.orders, amountOf)),
                })}
              </span>
              <ChevronDown
                aria-hidden="true"
                className="size-4 shrink-0 transition-transform group-data-[state=open]:rotate-180"
              />
            </button>
          </CollapsibleTrigger>
          <CollapsibleContent className="pb-2">
            <div className="overflow-hidden rounded-xl border">
              {children(day.orders)}
            </div>
          </CollapsibleContent>
        </Collapsible>
      ))}
    </div>
  )
}
