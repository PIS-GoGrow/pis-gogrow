import { Head, Link } from "@inertiajs/react"
import { ArrowLeft, Pencil, X } from "lucide-react"
import type { ReactNode } from "react"
import { useTranslation } from "react-i18next"

import { ConsumerMobileNav } from "@/components/consumer/consumer-mobile-nav"
import CancelOrderSheet from "@/components/orders/cancel-order-sheet"
import StatusBadge from "@/components/status-badge"
import { Button } from "@/components/ui/button"
import {
  Card,
  CardAction,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { Separator } from "@/components/ui/separator"
import { useFormatters } from "@/hooks/use-formatters"
import AppLayout from "@/layouts/app-layout"
import { consumerOrders } from "@/routes"
import type { BreadcrumbItem, ConsumerOrdersShow } from "@/types"

function Row({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div className="flex items-baseline justify-between gap-4 py-2">
      <dt className="text-muted-foreground text-sm">{label}</dt>
      <dd className="text-right text-sm font-medium">{children}</dd>
    </div>
  )
}

export default function Show({ order, historical }: ConsumerOrdersShow) {
  const { t } = useTranslation()
  const { formatMoney, formatLongDate } = useFormatters()

  const unitPrice =
    order.price != null && order.amount != null && order.amount > 0
      ? order.price / order.amount
      : null
  const showCancelAction = !historical || order.cancellable
  const showEditAction = !historical || order.modifiable

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.orders.index.title"),
      href: consumerOrders.index().url,
    },
    {
      title: t("pages.orders.show.title"),
      href: consumerOrders.show(order.id).url,
    },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t("pages.orders.show.title")} />

      {/* La navegación mobile es fija; este espacio evita que cubra el contenido. */}
      <div className="mx-auto grid w-full max-w-128 gap-4 p-5 pb-24 md:pb-5">
        <Button
          variant="ghost"
          size="sm"
          className="justify-self-start"
          asChild
        >
          <Link href={consumerOrders.index().url}>
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
              <StatusBadge status={order.status} />
            </CardAction>
          </CardHeader>

          <CardContent>
            <dl className="divide-border divide-y">
              {order.rejection_reason && (
                <Row label={t("pages.orders.show.rejection_reason")}>
                  {order.rejection_reason === "other"
                    ? order.rejection_details
                    : t(
                        "pages.provider_orders.rejection_reasons." +
                          order.rejection_reason,
                      )}
                </Row>
              )}

              <Row label={t("pages.orders.show.quantity")}>
                {order.amount ?? 0}
              </Row>

              <Row label={t("pages.orders.show.date")}>
                {order.date
                  ? formatLongDate(order.date)
                  : t("pages.orders.index.no_date")}
              </Row>

              {order.selected_options.map((option) => (
                <Row key={option.group_id} label={option.name}>
                  {option.values.join(", ")}
                </Row>
              ))}

              <Row label={t("pages.orders.show.delivery_method")}>
                {t(`pages.orders.delivery_methods.${order.delivery_method}`)}
              </Row>

              <Row label={t("pages.orders.show.address")}>
                {order.address ?? t("pages.orders.index.no_address")}
              </Row>

              <Row label={t("pages.orders.show.base_price")}>
                {unitPrice != null
                  ? formatMoney(unitPrice)
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
              <p className="min-w-0 text-sm [overflow-wrap:anywhere]">
                {order.notes ?? t("pages.orders.show.no_notes")}
              </p>
            </div>
          </CardContent>

          {/* En el historial no se reserva espacio para acciones no disponibles. */}
          {(showCancelAction || showEditAction) && (
            <CardFooter
              className={
                showCancelAction && showEditAction
                  ? "grid grid-cols-2 items-start gap-2"
                  : "grid grid-cols-1 items-start gap-2"
              }
            >
              {order.cancellable ? (
                <CancelOrderSheet order={order} />
              ) : (
                showCancelAction && (
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    className="w-full"
                    disabled
                  >
                    <X aria-hidden="true" />
                    {t("pages.orders.index.cancel")}
                  </Button>
                )
              )}
              {order.modifiable ? (
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  className="w-full"
                  asChild
                >
                  <Link href={consumerOrders.edit(order.id)}>
                    <Pencil aria-hidden="true" />
                    {t("pages.orders.show.edit")}
                  </Link>
                </Button>
              ) : (
                showEditAction && (
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    className="w-full"
                    disabled
                  >
                    <Pencil aria-hidden="true" />
                    {t("pages.orders.show.edit")}
                  </Button>
                )
              )}
              {!order.cancellable &&
                showCancelAction &&
                order.status !== "confirmed" &&
                order.cancellation_block_reason && (
                  <p className="col-span-full text-muted-foreground text-xs">
                    {t(
                      `pages.orders.index.cannot_cancel.${order.cancellation_block_reason}`,
                    )}
                  </p>
                )}
              {!order.modifiable &&
                showEditAction &&
                order.status !== "confirmed" &&
                order.modification_block_reason &&
                order.modification_block_reason !==
                  order.cancellation_block_reason && (
                  <p className="col-span-full text-muted-foreground text-xs">
                    {t(
                      `pages.orders.show.cannot_edit.${order.modification_block_reason}`,
                    )}
                  </p>
                )}
            </CardFooter>
          )}
        </Card>
      </div>

      {/* Mantiene en el detalle la misma navegación mobile del listado. */}
      <ConsumerMobileNav />
    </AppLayout>
  )
}
