import { Head } from "@inertiajs/react"
import { useTranslation } from "react-i18next"

import OrderCard from "@/components/orders/order-card"
import {
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyTitle,
} from "@/components/ui/empty"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { useFormatters } from "@/hooks/use-formatters"
import AppLayout from "@/layouts/app-layout"
import { orders as ordersRoutes } from "@/routes"
import type { BreadcrumbItem, Order, OrdersIndex } from "@/types"

// Las órdenes llegan ya ordenadas por fecha, así que alcanza con agrupar por
// primera aparición para que los encabezados queden en el orden del servidor.
const groupByDate = (orders: Order[]) =>
  orders.reduce<{ date: string | null; orders: Order[] }[]>((groups, order) => {
    const date = order.date ?? null
    const group = groups.find((candidate) => candidate.date === date)

    if (group) {
      group.orders.push(order)
    } else {
      groups.push({ date, orders: [order] })
    }

    return groups
  }, [])

export default function Index({ upcoming_orders, past_orders }: OrdersIndex) {
  const { t } = useTranslation()
  const { formatDeliveryDate } = useFormatters()

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.orders.index.title"),
      href: ordersRoutes.index().url,
    },
  ]

  const renderSection = (
    section: "upcoming" | "history",
    sectionOrders: Order[],
  ) =>
    sectionOrders.length === 0 ? (
      <Empty>
        <EmptyHeader>
          <EmptyTitle>
            {t(`pages.orders.index.${section}_empty_title`)}
          </EmptyTitle>
          <EmptyDescription>
            {t(`pages.orders.index.${section}_empty_description`)}
          </EmptyDescription>
        </EmptyHeader>
      </Empty>
    ) : (
      groupByDate(sectionOrders).map((group) => (
        <section key={group.date ?? "undated"} className="grid gap-2">
          <h2 className="text-muted-foreground text-sm">
            {group.date
              ? formatDeliveryDate(group.date)
              : t("pages.orders.index.no_date")}
          </h2>

          {group.orders.map((order) => (
            <OrderCard key={order.id} order={order} section={section} />
          ))}
        </section>
      ))
    )

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t("pages.orders.index.title")} />

      <div className="mx-auto grid w-full max-w-128 gap-6 p-5">
        <h1 className="text-2xl font-bold">{t("pages.orders.index.title")}</h1>

        <Tabs defaultValue="upcoming" className="gap-6">
          <TabsList className="w-full">
            <TabsTrigger value="upcoming">
              {t("pages.orders.index.upcoming_tab")}
            </TabsTrigger>
            <TabsTrigger value="history">
              {t("pages.orders.index.history_tab")}
            </TabsTrigger>
          </TabsList>

          <TabsContent value="upcoming" className="grid gap-5">
            {renderSection("upcoming", upcoming_orders)}
          </TabsContent>

          <TabsContent value="history" className="grid gap-5">
            {renderSection("history", past_orders)}
          </TabsContent>
        </Tabs>
      </div>
    </AppLayout>
  )
}
