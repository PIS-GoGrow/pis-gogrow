import { Head } from "@inertiajs/react"
import { Package } from "lucide-react"
import { useState } from "react"

import Heading from "@/components/heading"
import OrderCard, { type ProviderOrder } from "@/components/orders/order-card"
import type { OrderStatus } from "@/components/orders/order-status-badge"
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
import type { BreadcrumbItem } from "@/types"

type StatusFilter = "all" | OrderStatus

const filters: { value: StatusFilter; label: string }[] = [
  { value: "all", label: "Todos" },
  { value: "pending", label: "Pendientes" },
  { value: "confirmed", label: "Confirmados" },
  { value: "delivered", label: "Entregados" },
  { value: "cancelled", label: "Cancelados" },
]

// Datos de ejemplo mientras la pantalla no recibe los pedidos reales del proveedor.
const sampleOrders: ProviderOrder[] = [
  {
    id: 1058,
    consumer_name: "Martina Silva",
    time: "12:30",
    menu_name: "Wok de verduras + arroz",
    notes: "Sin picante · Sin cebolla",
    address: "Oficina GoGrow · 18 de Julio 1006",
    price: 300,
    status: "pending",
  },
  {
    id: 1057,
    consumer_name: "Lucas Pereira",
    time: "12:30",
    menu_name: "Sorrentinos artesanales",
    notes: "Caprese · Salsa de tomate",
    address: "Oficina GoGrow · 18 de Julio 1006",
    price: 320,
    status: "pending",
  },
  {
    id: 1053,
    consumer_name: "Camila Díaz",
    time: "13:00",
    menu_name: "Wok de verduras + arroz",
    notes: "Picante suave",
    address: "Av. Brasil 2145, apto. 402",
    price: 300,
    status: "confirmed",
  },
  {
    id: 1049,
    consumer_name: "Federico Costa",
    time: "12:30",
    menu_name: "Pollo al curry",
    notes: "Sin modificaciones",
    address: "Oficina GoGrow · 18 de Julio 1006",
    price: 360,
    status: "delivered",
  },
  {
    id: 1046,
    consumer_name: "Ana Rodríguez",
    time: "12:30",
    menu_name: "Sorrentinos artesanales",
    notes: "Jamón y queso",
    address: "Oficina GoGrow · 18 de Julio 1006",
    price: 320,
    status: "cancelled",
  },
]

export default function Index() {
  const [filter, setFilter] = useState<StatusFilter>("all")

  const orders =
    filter === "all"
      ? sampleOrders
      : sampleOrders.filter((order) => order.status === filter)

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

          {orders.length === 0 ? (
            <Empty className="border">
              <EmptyHeader>
                <EmptyMedia variant="icon">
                  <Package aria-hidden="true" />
                </EmptyMedia>
                <EmptyTitle>No hay pedidos</EmptyTitle>
                <EmptyDescription>
                  Todavía no tenés pedidos con este estado para hoy.
                </EmptyDescription>
              </EmptyHeader>
            </Empty>
          ) : (
            <div className="grid gap-4 md:grid-cols-2">
              {orders.map((order) => (
                <OrderCard key={order.id} order={order} />
              ))}
            </div>
          )}
        </div>
      </div>
    </AppLayout>
  )
}
