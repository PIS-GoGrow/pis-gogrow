import { Head } from "@inertiajs/react"
import { Search } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import DeliveryFilterSheet from "@/components/orders/delivery-filter-sheet"
import ProviderOrderDays from "@/components/orders/provider-order-days"
import PageContainer from "@/components/page-container"
import { Input } from "@/components/ui/input"
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs"
import AppLayout from "@/layouts/app-layout"
import {
  type DeliveryFilter,
  type StatusFilter,
  ordersColumns,
} from "@/lib/provider-orders"
import { cn } from "@/lib/utils"
import { providerOrders } from "@/routes"
import type { BreadcrumbItem, ProviderOrdersIndex } from "@/types"

type Period = "upcoming" | "history"

const periods: Period[] = ["upcoming", "history"]
const statusFilters: StatusFilter[] = ["pending", "confirmed", "all"]

export default function Index({
  today,
  upcoming_orders,
  past_orders,
}: ProviderOrdersIndex) {
  const { t } = useTranslation()
  const [period, setPeriod] = useState<Period>("upcoming")
  const [status, setStatus] = useState<StatusFilter>("all")
  const [delivery, setDelivery] = useState<DeliveryFilter>("all")
  const [search, setSearch] = useState("")

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.provider_orders.index.title"),
      href: providerOrders.index().url,
    },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t("pages.provider_orders.index.title")} />

      <PageContainer
        title={t("pages.provider_orders.index.title")}
        titleVariant="prominent"
      >
        <div className={cn("grid gap-4", ordersColumns)}>
          <Tabs
            value={period}
            onValueChange={(value) => setPeriod(value as Period)}
            className="lg:col-start-1 lg:row-start-2"
          >
            <TabsList className="w-full">
              {periods.map((value) => (
                <TabsTrigger key={value} value={value}>
                  {t(`pages.provider_orders.index.tabs.${value}`)}
                </TabsTrigger>
              ))}
            </TabsList>
          </Tabs>

          <Tabs
            value={status}
            onValueChange={(value) => setStatus(value as StatusFilter)}
            className="lg:col-start-2 lg:row-start-2"
          >
            <TabsList
              className="w-full"
              aria-label={t("pages.provider_orders.index.status_filter_label")}
            >
              {statusFilters.map((value) => (
                <TabsTrigger key={value} value={value}>
                  {t(`pages.provider_orders.index.status_filters.${value}`)}
                </TabsTrigger>
              ))}
            </TabsList>
          </Tabs>

          <div className="grid gap-4 lg:col-span-2 lg:row-start-1 lg:flex lg:flex-row-reverse lg:items-center lg:gap-6">
            <div className="flex items-center justify-between gap-2 lg:shrink-0 lg:gap-3">
              <p className="text-sm">
                {t("pages.provider_orders.index.delivery_label")}{" "}
                <span className="text-muted-foreground">
                  {t(
                    `pages.provider_orders.index.delivery_filters.${delivery}`,
                  )}
                </span>
              </p>
              <DeliveryFilterSheet value={delivery} onApply={setDelivery} />
            </div>

            <div className="relative lg:flex-1">
              <Input
                type="text"
                autoComplete="off"
                value={search}
                onChange={(event) => setSearch(event.target.value)}
                placeholder={t(
                  "pages.provider_orders.index.search_placeholder",
                )}
                aria-label={t("pages.provider_orders.index.search_label")}
                className="pr-9"
              />
              <Search
                className="text-muted-foreground pointer-events-none absolute top-1/2 right-3 size-4 -translate-y-1/2"
                aria-hidden="true"
              />
            </div>
          </div>
        </div>

        <ProviderOrderDays
          key={period}
          orders={period === "upcoming" ? upcoming_orders : past_orders}
          today={today}
          period={period}
          filters={{ status, delivery, search }}
        />
      </PageContainer>
    </AppLayout>
  )
}
