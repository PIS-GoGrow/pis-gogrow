import { Head, Link } from "@inertiajs/react"
import type { LucideIcon } from "lucide-react"
import { ArrowLeft, Building2, House, Mail, Phone } from "lucide-react"
import { type ReactNode, useState } from "react"
import { useTranslation } from "react-i18next"

import ProviderOrderActions from "@/components/orders/provider-order-actions"
import ProviderOrderDecidedSheet, {
  type ProviderOrderDecision,
} from "@/components/orders/provider-order-decided-sheet"
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

export default function Show({ order }: ProviderOrdersShow) {
  const { t } = useTranslation()
  const { formatMoney, formatDateWithYear } = useFormatters()
  const [decision, setDecision] = useState<ProviderOrderDecision | null>(null)

  // Solo lo que el empleado eligió: los pedidos anteriores a la personalización
  // no tienen elección.
  const chosenOptions = order.selected_options.filter(
    (option) => option.values.length > 0,
  )

  const code = t("pages.provider_orders.index.number", { id: order.id })
  const heading = t("pages.provider_orders.show.heading")
  // Un pedido caído no se le cobra a nadie: el total queda tachado.
  const notCharged = order.status === "cancelled" || order.status === "rejected"
  // Con "Otro motivo" el texto libre es el motivo: repetir la etiqueta
  // genérica al lado no agrega nada.
  const details = order.rejection_details?.trim()
  const rejectionText =
    details && details.length > 0
      ? details
      : order.rejection_reason
        ? t(`pages.provider_orders.rejection_reasons.${order.rejection_reason}`)
        : null
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
        <Card className="md:bg-muted/30 gap-4 border-0 bg-transparent py-0 shadow-none md:gap-6 md:border md:py-6">
          <CardContent className="grid gap-4 px-0 md:gap-6 md:px-6">
            <div className="grid justify-items-center gap-2 text-center">
              <StatusBadge status={order.status} kind="provider_order" />
              <h3 className="text-xl font-bold tracking-tight md:text-2xl">
                {t("pages.provider_orders.show.title", { code })}
              </h3>
              <p className="text-muted-foreground text-sm">
                {`${formatDateWithYear(order.created_on)} · ${order.time}`}
              </p>
            </div>

            <div className="grid gap-4 md:grid-cols-[3fr_2fr]">
              <Card
                className={cn(
                  "min-w-0 gap-3 py-4 shadow-none md:gap-4 md:py-6 md:shadow-sm",
                  rejectionText && "md:row-span-2",
                )}
              >
                <CardHeader className="px-4 md:px-6">
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
                <CardContent className="grid gap-3 px-4 md:gap-4 md:px-6">
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

              <Card className="min-w-0 gap-3 py-4 shadow-none md:gap-4 md:py-6 md:shadow-sm">
                <CardHeader className="px-4 md:px-6">
                  <CardDescription>
                    {t("pages.provider_orders.show.order_detail")}
                  </CardDescription>
                </CardHeader>
                <CardContent className="grid gap-3 px-4 md:gap-4 md:px-6">
                  <div className="grid gap-1">
                    <div className="flex items-baseline justify-between gap-4">
                      <span className="min-w-0 break-words">
                        {order.menu_name}
                      </span>
                      <span>
                        {t("pages.provider_orders.index.quantity", {
                          count: order.amount ?? 0,
                        })}
                      </span>
                    </div>
                    {chosenOptions.map((option) => (
                      <p
                        key={option.group_id}
                        className="text-muted-foreground text-sm"
                      >
                        {`${option.name}: ${option.values.join(" · ")}`}
                      </p>
                    ))}
                  </div>
                  <Separator />
                  <div className="flex items-baseline justify-between gap-4">
                    <span className="text-muted-foreground text-sm">
                      {t("pages.provider_orders.show.total")}
                    </span>
                    <span
                      className={cn(
                        "text-lg font-semibold",
                        notCharged && "text-muted-foreground line-through",
                      )}
                    >
                      {formatMoney(order.price)}
                    </span>
                  </div>
                  {notCharged && (
                    <p className="text-destructive text-sm">
                      {t("pages.provider_orders.show.not_charged")}
                    </p>
                  )}
                  {order.notes && (
                    <>
                      <Separator />
                      <div className="grid gap-1">
                        <span className="text-muted-foreground text-sm font-medium">
                          {t("pages.provider_orders.show.notes")}
                        </span>
                        <p className="text-sm break-words">{order.notes}</p>
                      </div>
                    </>
                  )}
                </CardContent>
              </Card>

              {rejectionText && (
                <Card className="min-w-0 gap-3 py-4 shadow-none md:col-start-2 md:gap-4 md:py-6 md:shadow-sm">
                  <CardHeader className="px-4 md:px-6">
                    <CardDescription>
                      {t("pages.provider_orders.show.rejection_reason")}
                    </CardDescription>
                  </CardHeader>
                  <CardContent className="px-4 break-words md:px-6">
                    {rejectionText}
                  </CardContent>
                </Card>
              )}
            </div>
          </CardContent>
        </Card>

        <ProviderOrderActions
          order={order}
          stackOnMobile
          onDecided={setDecision}
          className="mx-auto w-full pb-[env(safe-area-inset-bottom)] md:mt-6 md:max-w-md md:pb-0"
        />
      </PageContainer>

      <ProviderOrderDecidedSheet
        decision={decision}
        onClose={() => setDecision(null)}
      />
    </AppLayout>
  )
}
