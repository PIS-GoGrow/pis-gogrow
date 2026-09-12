import { Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"
import type { ReactNode } from "react"
import { useTranslation } from "react-i18next"

import OrderStatusBadge from "@/components/orders/order-status-badge"
import { Button } from "@/components/ui/button"
import {
  Card,
  CardAction,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { Separator } from "@/components/ui/separator"
import { useFormatters } from "@/hooks/use-formatters"
import AppLayout from "@/layouts/app-layout"
import { orders as ordersRoutes } from "@/routes"
import type { BreadcrumbItem, OrdersShow } from "@/types"

function Row({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div className="flex items-baseline justify-between gap-4 py-2">
      <dt className="text-muted-foreground text-sm">{label}</dt>
      <dd className="text-right text-sm font-medium">{children}</dd>
    </div>
  )
}

export default function Show({ order }: OrdersShow) {
  const { t } = useTranslation()
  const { formatMoney, formatDeliveryDate } = useFormatters()

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.orders.index.title"),
      href: ordersRoutes.index().url,
    },
    {
      title: t("pages.orders.show.title"),
      href: ordersRoutes.show(order.id).url,
    },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t("pages.orders.show.title")} />

      <div className="mx-auto grid w-full max-w-128 gap-4 p-5">
        <Button
          variant="ghost"
          size="sm"
          className="justify-self-start"
          asChild
        >
          <Link href={ordersRoutes.index().url}>
            <ArrowLeft />
            {t("pages.orders.show.back")}
          </Link>
        </Button>

        <Card>
          <CardHeader>
            <CardDescription>
              {order.provider_name ?? t("pages.orders.index.no_provider")}
            </CardDescription>
            <CardTitle className="text-lg">
              {order.menu_name ?? t("pages.orders.index.no_menu")}
            </CardTitle>
            <CardAction>
              <OrderStatusBadge status={order.status} />
            </CardAction>
          </CardHeader>

          <CardContent>
            <dl className="divide-border divide-y">
              <Row label={t("pages.orders.show.quantity")}>
                {order.amount ?? 0}
              </Row>

              <Row label={t("pages.orders.show.date")}>
                {order.date
                  ? formatDeliveryDate(order.date)
                  : t("pages.orders.index.no_date")}
              </Row>

              <Row label={t("pages.orders.show.address")}>
                {order.address ?? t("pages.orders.index.no_address")}
              </Row>

              <Row label={t("pages.orders.show.base_price")}>
                {order.price != null
                  ? formatMoney(order.price)
                  : t("pages.orders.index.no_price")}
              </Row>

              <Row label={t("pages.orders.show.subsidy")}>
                {order.subsidy != null
                  ? formatMoney(order.subsidy)
                  : t("pages.orders.index.no_price")}
              </Row>

              <Row label={t("pages.orders.show.total")}>
                {order.discounted_price != null
                  ? formatMoney(order.discounted_price)
                  : t("pages.orders.index.no_price")}
              </Row>
            </dl>

            <Separator className="my-4" />

            <div className="grid gap-1">
              <p className="text-muted-foreground text-sm">
                {t("pages.orders.show.notes")}
              </p>
              <p className="text-sm">
                {order.notes ?? t("pages.orders.show.no_notes")}
              </p>
            </div>
          </CardContent>
        </Card>
      </div>
    </AppLayout>
  )
}
