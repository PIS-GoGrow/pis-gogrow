import { Head, InfiniteScroll, usePage } from "@inertiajs/react"
import { useEffect, useState } from "react"
import { useTranslation } from "react-i18next"

import { ConsumerMobileNav } from "@/components/consumer/consumer-mobile-nav"
import { ProviderFilterSheet } from "@/components/consumer/provider-filter-sheet"
import OrderCancelledSheet from "@/components/orders/order-cancelled-sheet"
import OrderCard from "@/components/orders/order-card"
import {
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyTitle,
} from "@/components/ui/empty"
import { Spinner } from "@/components/ui/spinner"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { useFormatters } from "@/hooks/use-formatters"
import AppLayout from "@/layouts/app-layout"
import { db } from "@/lib/offline-db"
import { consumerOrders } from "@/routes"
import type { BreadcrumbItem, ConsumerOrdersIndex, Order } from "@/types"

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

export default function Index({
  upcoming_orders,
  past_orders,
  providers,
}: ConsumerOrdersIndex) {
  const { t } = useTranslation()
  const { formatLongDate } = useFormatters()
  const { auth } = usePage().props

  useEffect(() => {
    db.consumer_orders.put({
      id: 1,
      session_id: auth.session.id,
      upcoming_orders,
      saved_at: Date.now(),
    })
  }, [upcoming_orders, auth.session.id])

  const [activeProviders, setActiveProviders] = useState<Set<number>>(new Set())
  const selectedProviderId = activeProviders.values().next().value
  const byProvider = (orders: Order[]) =>
    selectedProviderId == null
      ? orders
      : orders.filter((order) => order.provider_id === selectedProviderId)
  const filteredUpcomingOrders = byProvider(upcoming_orders)
  const filteredPastOrders = byProvider(past_orders)
  const filterLabel =
    providers.find((provider) => provider.id === selectedProviderId)?.name ??
    t("pages.orders.index.all_providers")

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.orders.index.title"),
      href: consumerOrders.index().url,
    },
  ]

  const renderEmpty = (section: "upcoming" | "history") => (
    <Empty>
      <EmptyHeader>
        <EmptyTitle>
          {t(
            activeProviders.size > 0
              ? `pages.orders.index.${section}_filtered_empty_title`
              : `pages.orders.index.${section}_empty_title`,
          )}
        </EmptyTitle>
        <EmptyDescription>
          {t(
            activeProviders.size > 0
              ? `pages.orders.index.${section}_filtered_empty_description`
              : `pages.orders.index.${section}_empty_description`,
          )}
        </EmptyDescription>
      </EmptyHeader>
    </Empty>
  )

  const renderGroups = (
    section: "upcoming" | "history",
    sectionOrders: Order[],
  ) =>
    groupByDate(sectionOrders).map((group) => (
      <section key={group.date ?? "undated"} className="grid gap-2">
        <h2 className="text-muted-foreground text-sm">
          {group.date
            ? formatLongDate(group.date)
            : t("pages.orders.index.no_date")}
        </h2>

        {group.orders.map((order) => (
          <OrderCard key={order.id} order={order} section={section} />
        ))}
      </section>
    ))

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t("pages.orders.index.title")} />

      <div className="mx-auto grid w-full max-w-128 gap-6 p-5 pb-24 md:pb-5">
        <h1 className="text-2xl font-bold">{t("pages.orders.index.title")}</h1>

        <div className="flex items-center">
          <span className="text-foreground min-w-0 truncate text-sm font-medium">
            {t("pages.orders.index.providers_label")}{" "}
            <span className="text-muted-foreground font-normal">
              {filterLabel}
            </span>
          </span>
          <ProviderFilterSheet
            providers={providers}
            selectedProviders={activeProviders}
            onApply={setActiveProviders}
            selectionMode="single"
            allProvidersLabel={t("pages.orders.index.all_providers")}
          />
        </div>

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
            {filteredUpcomingOrders.length === 0
              ? renderEmpty("upcoming")
              : renderGroups("upcoming", filteredUpcomingOrders)}
          </TabsContent>

          <TabsContent value="history" className="grid gap-5">
            <InfiniteScroll
              data="past_orders"
              preserveUrl
              className="grid gap-5"
              next={({ loading, hasMore }) =>
                loading ? (
                  <div className="text-muted-foreground flex items-center justify-center gap-2 py-4 text-sm">
                    <Spinner aria-hidden="true" />
                    {t("pages.orders.index.history_loading")}
                  </div>
                ) : hasMore || filteredPastOrders.length > 0 ? null : (
                  renderEmpty("history")
                )
              }
            >
              {renderGroups("history", filteredPastOrders)}
            </InfiniteScroll>
          </TabsContent>
        </Tabs>
      </div>

      <OrderCancelledSheet />
      <ConsumerMobileNav />
    </AppLayout>
  )
}
