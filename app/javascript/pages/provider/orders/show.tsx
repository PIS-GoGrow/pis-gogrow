import { Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"
import { useTranslation } from "react-i18next"

import PageContainer from "@/components/page-container"
import StatusBadge from "@/components/status-badge"
import { buttonVariants } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Separator } from "@/components/ui/separator"
import { useFormatters } from "@/hooks/use-formatters"
import AppLayout from "@/layouts/app-layout"
import { providerOrders } from "@/routes"
import type { BreadcrumbItem, ProviderOrdersShow } from "@/types"

export default function Show({ order }: ProviderOrdersShow) {
  const { t } = useTranslation()
  const { formatMoney, formatDeliveryDate } = useFormatters()

  const code = t("pages.provider_orders.index.code", { id: order.id })

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.provider_orders.index.title"),
      href: providerOrders.index().url,
    },
    {
      title: code,
      href: providerOrders.show(order.id).url,
    },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t("pages.provider_orders.show.title", { code })} />

      <PageContainer
        eyebrow={t("pages.provider_orders.show.eyebrow")}
        title={code}
        actions={<StatusBadge status={order.status} />}
      >
        <Link
          href={providerOrders.index()}
          className={buttonVariants({ variant: "ghost", size: "sm" })}
        >
          <ArrowLeft aria-hidden="true" />
          {t("pages.provider_orders.show.back")}
        </Link>

        <div className="grid gap-4 md:grid-cols-2">
          <Card>
            <CardHeader>
              <CardTitle>{t("pages.provider_orders.show.summary")}</CardTitle>
            </CardHeader>
            <CardContent className="grid gap-1 text-sm">
              <p>
                {order.date
                  ? t("pages.provider_orders.show.delivery_date", {
                      date: formatDeliveryDate(order.date),
                    })
                  : t("pages.provider_orders.show.no_delivery_date")}
              </p>
              <p className="text-muted-foreground">
                {t("pages.provider_orders.show.ordered_at", {
                  time: order.time,
                })}
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>{t("pages.provider_orders.show.customer")}</CardTitle>
            </CardHeader>
            <CardContent className="grid gap-1 text-sm">
              <p className="font-medium">{order.consumer_name}</p>
              <p className="text-muted-foreground">
                {order.consumer_company ??
                  t("pages.provider_orders.show.no_company")}
              </p>
              <p className="text-muted-foreground">{order.consumer_email}</p>
              <Separator className="my-2" />
              <p className="font-medium">
                {t("pages.provider_orders.show.delivery_address")}
              </p>
              <p className="text-muted-foreground">
                {order.address ?? t("pages.provider_orders.show.no_address")}
              </p>
              <p className="text-muted-foreground">
                {t("pages.provider_orders.show.delivery_method", {
                  method: t(
                    `pages.orders.delivery_methods.${order.delivery_method}`,
                  ),
                })}
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>
                {t("pages.provider_orders.show.preparation")}
              </CardTitle>
            </CardHeader>
            <CardContent className="grid gap-1 text-sm">
              <p className="font-medium">{order.menu_name}</p>
              {order.menu_description && (
                <p className="text-muted-foreground">
                  {order.menu_description}
                </p>
              )}
              <p>
                {t("pages.provider_orders.show.quantity", {
                  count: order.amount ?? 0,
                })}
              </p>
              {order.menu_sauces.length > 0 && (
                <p className="text-muted-foreground">
                  {t("pages.provider_orders.show.sauces")}:{" "}
                  {order.menu_sauces.join(" · ")}
                </p>
              )}
              {order.menu_fillings.length > 0 && (
                <p className="text-muted-foreground">
                  {t("pages.provider_orders.show.fillings")}:{" "}
                  {order.menu_fillings.join(" · ")}
                </p>
              )}
              <Separator className="my-2" />
              <p className="font-medium">
                {t("pages.provider_orders.show.notes")}
              </p>
              <p className="text-muted-foreground">
                {order.notes ?? t("pages.provider_orders.show.no_notes")}
              </p>
              <Separator className="my-2" />
              <p className="font-medium">
                {t("pages.provider_orders.show.stock")}
              </p>
              <p className="text-muted-foreground">
                {order.schedule_amount == null || order.remaining_amount == null
                  ? t("pages.provider_orders.show.no_stock")
                  : t("pages.provider_orders.show.stock_detail", {
                      remaining: order.remaining_amount,
                      total: order.schedule_amount,
                    })}
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>{t("pages.provider_orders.show.amounts")}</CardTitle>
            </CardHeader>
            <CardContent className="grid gap-2 text-sm">
              <div className="flex items-baseline justify-between gap-3">
                <span className="text-muted-foreground">
                  {t("pages.provider_orders.show.base_price")}
                </span>
                <span>{formatMoney(order.price)}</span>
              </div>
              {order.subsidy != null && (
                <div className="flex items-baseline justify-between gap-3">
                  <span className="text-muted-foreground">
                    {t("pages.provider_orders.show.subsidy")}
                  </span>
                  <span>-{formatMoney(order.subsidy)}</span>
                </div>
              )}
              <Separator />
              <div className="flex items-baseline justify-between gap-3">
                <span className="font-medium">
                  {t("pages.provider_orders.show.charged")}
                </span>
                <span className="text-lg font-semibold">
                  {order.discounted_price == null
                    ? t("pages.provider_orders.show.no_price")
                    : formatMoney(order.discounted_price)}
                </span>
              </div>
            </CardContent>
          </Card>
        </div>
      </PageContainer>
    </AppLayout>
  )
}
