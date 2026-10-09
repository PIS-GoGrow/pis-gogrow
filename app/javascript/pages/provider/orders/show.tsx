import { Head, Link } from "@inertiajs/react"
import type { LucideIcon } from "lucide-react"
import { ArrowLeft, Building2, House, Mail, Phone } from "lucide-react"
import type { ReactNode } from "react"
import { useTranslation } from "react-i18next"

import ProviderOrderActions from "@/components/orders/provider-order-actions"
import PageContainer from "@/components/page-container"
import StatusBadge from "@/components/status-badge"
import { Button } from "@/components/ui/button"
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { Separator } from "@/components/ui/separator"
import { useFormatters } from "@/hooks/use-formatters"
import AppLayout from "@/layouts/app-layout"
import { cn } from "@/lib/utils"
import { providerOrders } from "@/routes"
import type { BreadcrumbItem, ProviderOrdersShow } from "@/types"

function InfoRow({
  icon: Icon,
  muted = false,
  children,
}: {
  icon: LucideIcon
  muted?: boolean
  children: ReactNode
}) {
  return (
    <div className="flex items-center gap-3 text-sm">
      <Icon
        className="text-muted-foreground size-4 shrink-0"
        aria-hidden="true"
      />
      <span
        className={cn("min-w-0 break-words", muted && "text-muted-foreground")}
      >
        {children}
      </span>
    </div>
  )
}

function DetailLine({
  label,
  children,
}: {
  label: string
  children: ReactNode
}) {
  return (
    <div className="flex items-baseline justify-between gap-4 text-sm">
      <span className="text-muted-foreground">{label}</span>
      <span className="text-right">{children}</span>
    </div>
  )
}

export default function Show({ order }: ProviderOrdersShow) {
  const { t } = useTranslation()
  const { formatMoneyShort, formatLongDate } = useFormatters()

  // Solo lo que el empleado eligió: los pedidos anteriores a la personalización
  // no tienen elección.
  const chosenOptions = order.selected_options.filter(
    (option) => option.values.length > 0,
  )

  const code = t("pages.provider_orders.index.code", { id: order.id })
  const heading = t("pages.provider_orders.show.heading")
  const DeliveryIcon = order.delivery_method === "home" ? House : Building2

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
      <Head title={heading} />

      <PageContainer
        centered
        compactHeading
        title={heading}
        back={
          <Button asChild variant="ghost" size="icon" className="-ml-2.5">
            <Link
              href={providerOrders.index()}
              aria-label={t("pages.provider_orders.show.back")}
            >
              <ArrowLeft aria-hidden="true" />
            </Link>
          </Button>
        }
      >
        <Card className="bg-muted/30 shadow-none">
          <CardContent className="grid gap-6">
            <div className="grid justify-items-center gap-2 text-center">
              <StatusBadge status={order.status} kind="provider_order" />
              <h3 className="text-2xl font-bold tracking-tight">
                {t("pages.provider_orders.show.title", { code })}
              </h3>
              <p className="text-muted-foreground text-sm">
                {`${formatLongDate(order.created_on)} · ${order.time}`}
              </p>
            </div>

            <div className="grid gap-4 md:grid-cols-[3fr_2fr]">
              <Card className="gap-4">
                <CardHeader>
                  <CardDescription>
                    {order.consumer_company
                      ? t("pages.provider_orders.show.employee_company", {
                          company: order.consumer_company,
                        })
                      : t("pages.provider_orders.show.employee")}
                  </CardDescription>
                  <CardTitle className="text-xl">
                    {order.consumer_name}
                  </CardTitle>
                </CardHeader>
                <CardContent className="grid gap-4">
                  <Separator />
                  <InfoRow icon={Mail}>{order.consumer_email}</InfoRow>
                  {/* El teléfono todavía no se guarda: la fila queda hasta que llegue el dato. */}
                  <InfoRow icon={Phone} muted>
                    {t("pages.provider_orders.show.phone_unavailable")}
                  </InfoRow>
                  <InfoRow icon={DeliveryIcon}>
                    {`${t(`pages.provider_orders.index.delivery_methods.${order.delivery_method}`)} · ${order.address ?? t("pages.provider_orders.index.no_address")}`}
                  </InfoRow>
                </CardContent>
              </Card>

              <Card className="gap-4">
                <CardHeader>
                  <CardDescription>
                    {t("pages.provider_orders.show.order_detail")}
                  </CardDescription>
                </CardHeader>
                <CardContent className="grid gap-4">
                  <div className="grid gap-1">
                    <div className="flex items-baseline justify-between gap-4">
                      <span>{order.menu_name}</span>
                      <span>
                        {t("pages.provider_orders.index.quantity", {
                          count: order.amount ?? 0,
                        })}
                      </span>
                    </div>
                    {order.menu_description && (
                      <p className="text-muted-foreground text-sm">
                        {order.menu_description}
                      </p>
                    )}
                  </div>
                  {chosenOptions.map((option) => (
                    <DetailLine key={option.group_id} label={option.name}>
                      {option.values.join(" · ")}
                    </DetailLine>
                  ))}
                  {order.notes && (
                    <DetailLine label={t("pages.provider_orders.show.notes")}>
                      {order.notes}
                    </DetailLine>
                  )}
                  {order.date && (
                    <DetailLine
                      label={t("pages.provider_orders.show.delivery_date")}
                    >
                      {formatLongDate(order.date)}
                    </DetailLine>
                  )}
                  <Separator />
                  <div className="flex items-baseline justify-between gap-4">
                    <span className="text-muted-foreground text-sm">
                      {t("pages.provider_orders.show.total")}
                    </span>
                    <span className="text-lg font-semibold">
                      {formatMoneyShort(order.price)}
                    </span>
                  </div>
                </CardContent>
              </Card>
            </div>
          </CardContent>
        </Card>

        <ProviderOrderActions
          order={order}
          keepVisible
          className="mx-auto mt-6 w-full max-w-md"
        />
      </PageContainer>
    </AppLayout>
  )
}
