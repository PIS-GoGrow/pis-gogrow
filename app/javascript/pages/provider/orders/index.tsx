import { Head } from "@inertiajs/react"
import { Package } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import ProviderOrderCard from "@/components/orders/provider-order-card"
import PageContainer from "@/components/page-container"
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

const filters: StatusFilter[] = [
  "all",
  "pending",
  "confirmed",
  "cancelled",
  "rejected",
]

export default function Index({ orders }: ProviderOrdersIndex) {
  const { t } = useTranslation()
  const [filter, setFilter] = useState<StatusFilter>("all")

  const visibleOrders =
    filter === "all"
      ? orders
      : orders.filter((order) => order.status === filter)

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
        eyebrow={t("pages.provider_orders.index.eyebrow")}
        title={t("pages.provider_orders.index.title")}
      >
        <div className="overflow-x-auto pb-1">
          <ToggleGroup
            type="single"
            variant="outline"
            size="sm"
            spacing={2}
            value={filter}
            onValueChange={(value) => value && setFilter(value as StatusFilter)}
            aria-label={t("pages.provider_orders.index.filter_label")}
          >
            {filters.map((value) => (
              <ToggleGroupItem
                key={value}
                value={value}
                className="data-[state=on]:bg-primary data-[state=on]:text-primary-foreground data-[state=on]:hover:bg-primary/90 data-[state=on]:hover:text-primary-foreground rounded-full px-4"
              >
                {t(`pages.provider_orders.index.filters.${value}`)}
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
              <EmptyTitle>
                {t("pages.provider_orders.index.empty_title")}
              </EmptyTitle>
              <EmptyDescription>
                {filter === "all"
                  ? t("pages.provider_orders.index.empty_description")
                  : t("pages.provider_orders.index.empty_filtered_description")}
              </EmptyDescription>
            </EmptyHeader>
          </Empty>
        ) : (
          <div className="grid gap-4 md:grid-cols-2">
            {visibleOrders.map((order) => (
              <ProviderOrderCard key={order.id} order={order} />
            ))}
          </div>
        )}
      </PageContainer>
    </AppLayout>
  )
}
