import { Head } from "@inertiajs/react"
import { Package } from "lucide-react"
import { useState } from "react"

import Heading from "@/components/heading"
import OrderCard from "@/components/orders/order-card"
import {
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyMedia,
  EmptyTitle,
} from "@/components/ui/empty"
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group"
import AppLayout from "@/layouts/app-layout"
import { providerOrders } from "@/routes"
import type { BreadcrumbItem, OrderStatus, ProviderOrdersIndex } from "@/types"

type StatusFilter = "all" | OrderStatus

const filters: { value: StatusFilter; label: string }[] = [
  { value: "all", label: "Todos" },
  { value: "pending", label: "Pendientes" },
  { value: "confirmed", label: "Confirmados" },
  { value: "delivered", label: "Entregados" },
  { value: "cancelled", label: "Cancelados" },
]

export default function Index({ orders }: ProviderOrdersIndex) {
  const [filter, setFilter] = useState<StatusFilter>("all")

  const visibleOrders =
    filter === "all"
      ? orders
      : orders.filter((order) => order.status === filter)

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: "Pedidos",
      href: providerOrders.index().url,
    },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title="Pedidos" />

      <div className="mx-auto w-full max-w-5xl p-4 md:p-6">
        <Heading eyebrow="Operación diaria" title="Pedidos" />

        <div className="flex flex-col gap-4">
          <div className="-mx-4 overflow-x-auto px-4 pb-1 md:mx-0 md:px-0">
            <ToggleGroup
              type="single"
              variant="outline"
              size="sm"
              spacing={2}
              value={filter}
              onValueChange={(value) =>
                value && setFilter(value as StatusFilter)
              }
              aria-label="Filtrar pedidos por estado"
            >
              {filters.map(({ value, label }) => (
                <ToggleGroupItem
                  key={value}
                  value={value}
                  className="data-[state=on]:bg-primary data-[state=on]:text-primary-foreground data-[state=on]:hover:bg-primary/90 data-[state=on]:hover:text-primary-foreground rounded-full px-4"
                >
                  {label}
                </ToggleGroupItem>
              ))}
            </ToggleGroup>
          </div>

          {visibleOrders.length === 0 ? (
            <Empty className="border">
              <EmptyHeader>
                <EmptyMedia variant="icon">
                  <Package aria-hidden="true" />
                </EmptyMedia>
                <EmptyTitle>No hay pedidos</EmptyTitle>
                <EmptyDescription>
                  {filter === "all"
                    ? "Todavía no recibiste pedidos para hoy."
                    : "No tenés pedidos con este estado para hoy."}
                </EmptyDescription>
              </EmptyHeader>
            </Empty>
          ) : (
            <div className="grid gap-4 md:grid-cols-2">
              {visibleOrders.map((order) => (
                <OrderCard key={order.id} order={order} />
              ))}
            </div>
          )}
        </div>
      </div>
    </AppLayout>
  )
}
