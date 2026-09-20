import { Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"
import type { ReactNode } from "react"
import { useTranslation } from "react-i18next"

import HeadingSmall from "@/components/heading-small"
import PageContainer from "@/components/page-container"
import StatusBadge from "@/components/status-badge"
import { buttonVariants } from "@/components/ui/button"
import { useFormatters } from "@/hooks/use-formatters"
import AppLayout from "@/layouts/app-layout"
import { providerOrders } from "@/routes"
import type { BreadcrumbItem, ProviderOrdersShow } from "@/types"

function Section({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="grid gap-3 border-b pb-4 last:border-b-0 last:pb-0">
      <HeadingSmall title={title} />
      <dl className="grid gap-2 text-sm">{children}</dl>
    </section>
  )
}

function Row({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div className="flex flex-wrap items-baseline justify-between gap-x-6 gap-y-1">
      <dt className="text-muted-foreground">{label}</dt>
      <dd className="text-right">{children}</dd>
    </div>
  )
}

export default function Show({ order }: ProviderOrdersShow) {
  const { t } = useTranslation()
  const { formatMoney, formatDeliveryDate } = useFormatters()

  const code = t("pages.provider_orders.index.code", { id: order.id })
  const empty = t("pages.provider_orders.show.empty")

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
        actions={
          <Link
            href={providerOrders.index()}
            className={buttonVariants({ variant: "outline", size: "sm" })}
          >
            <ArrowLeft aria-hidden="true" />
            {t("pages.provider_orders.show.back")}
          </Link>
        }
      >
        <Section title={t("pages.provider_orders.show.summary")}>
          <Row label={t("pages.provider_orders.show.status")}>
            <StatusBadge status={order.status} />
          </Row>
          <Row label={t("pages.provider_orders.show.delivery_date")}>
            {order.date
              ? formatDeliveryDate(order.date)
              : t("pages.provider_orders.show.no_delivery_date")}
          </Row>
          <Row label={t("pages.provider_orders.show.ordered_at")}>
            {order.time}
          </Row>
        </Section>

        <Section title={t("pages.provider_orders.show.customer")}>
          <Row label={t("pages.provider_orders.show.name")}>
            {order.consumer_name}
          </Row>
          <Row label={t("pages.provider_orders.show.company")}>
            {order.consumer_company ??
              t("pages.provider_orders.show.no_company")}
          </Row>
          <Row label={t("pages.provider_orders.show.email")}>
            {order.consumer_email}
          </Row>
          <Row label={t("pages.provider_orders.show.delivery_address")}>
            {order.address ?? t("pages.provider_orders.show.no_address")}
          </Row>
          <Row label={t("pages.provider_orders.show.delivery_method")}>
            {t(`pages.orders.delivery_methods.${order.delivery_method}`)}
          </Row>
        </Section>

        <Section title={t("pages.provider_orders.show.preparation")}>
          <Row label={t("pages.provider_orders.show.menu")}>
            {order.menu_name}
          </Row>
          <Row label={t("pages.provider_orders.show.description")}>
            {order.menu_description ?? empty}
          </Row>
          <Row label={t("pages.provider_orders.show.quantity")}>
            {order.amount ?? empty}
          </Row>
          {order.menu_sauces.length > 0 && (
            <Row label={t("pages.provider_orders.show.sauces")}>
              {order.menu_sauces.join(" · ")}
            </Row>
          )}
          {order.menu_fillings.length > 0 && (
            <Row label={t("pages.provider_orders.show.fillings")}>
              {order.menu_fillings.join(" · ")}
            </Row>
          )}
          <Row label={t("pages.provider_orders.show.notes")}>
            {order.notes ?? t("pages.provider_orders.show.no_notes")}
          </Row>
          <Row label={t("pages.provider_orders.show.stock")}>
            {order.schedule_amount == null || order.remaining_amount == null
              ? t("pages.provider_orders.show.no_stock")
              : t("pages.provider_orders.show.stock_detail", {
                  remaining: order.remaining_amount,
                  total: order.schedule_amount,
                })}
          </Row>
        </Section>

        <Section title={t("pages.provider_orders.show.amounts")}>
          <Row label={t("pages.provider_orders.show.base_price")}>
            {formatMoney(order.price)}
          </Row>
          {order.subsidy != null && (
            <Row label={t("pages.provider_orders.show.subsidy")}>
              -{formatMoney(order.subsidy)}
            </Row>
          )}
          <Row label={t("pages.provider_orders.show.charged")}>
            <span className="text-lg font-semibold">
              {order.discounted_price == null
                ? t("pages.provider_orders.show.no_price")
                : formatMoney(order.discounted_price)}
            </span>
          </Row>
        </Section>
      </PageContainer>
    </AppLayout>
  )
}
