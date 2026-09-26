import { Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"
import type { ReactNode } from "react"
import { useTranslation } from "react-i18next"

import HeadingSmall from "@/components/heading-small"
import ListItemCard from "@/components/list-item-card"
import PageContainer from "@/components/page-container"
import StatusBadge from "@/components/status-badge"
import { buttonVariants } from "@/components/ui/button"
import { CardContent } from "@/components/ui/card"
import { useFormatters } from "@/hooks/use-formatters"
import AppLayout from "@/layouts/app-layout"
import { cn } from "@/lib/utils"
import { providerCollections } from "@/routes"
import type { BreadcrumbItem, ProviderCollectionsShow } from "@/types"

function Section({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="grid gap-3 border-b pb-4 last:border-b-0 last:pb-0">
      <HeadingSmall title={title} />
      {children}
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

export default function Show({
  account,
  orders,
  payments,
}: ProviderCollectionsShow) {
  const { t } = useTranslation()
  const { formatMoney } = useFormatters()

  const title = t("pages.provider_collections.show.title", {
    name: account.owner_name,
  })

  // La cuenta de la empresa cobra el subsidio; la del empleado, su parte.
  const amountOf = (order: (typeof orders)[number]) =>
    account.source === "company" ? order.subsidy : order.charged

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.provider_collections.index.title"),
      href: providerCollections.index().url,
    },
    {
      title: account.owner_name,
      href: providerCollections.show(account.id).url,
    },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={title} />

      <PageContainer
        eyebrow={t("pages.provider_collections.show.eyebrow")}
        title={title}
        back={
          <Link
            href={providerCollections.index()}
            // El -ml-2.5 come el padding del botón para que el texto quede
            // alineado con el título, no corrido a la derecha.
            className={cn(
              buttonVariants({ variant: "ghost", size: "sm" }),
              "-ml-2.5",
            )}
          >
            <ArrowLeft aria-hidden="true" />
            {t("pages.provider_collections.show.back")}
          </Link>
        }
      >
        <Section title={t("pages.provider_collections.show.summary")}>
          <dl className="grid gap-2 text-sm">
            <Row label={t("pages.provider_collections.show.period")}>
              {account.month}
            </Row>
            <Row label={t("pages.provider_collections.show.status")}>
              <StatusBadge status={account.status} kind="payment" />
            </Row>
            <Row label={t("pages.provider_collections.show.due_date")}>
              {account.due_date}
            </Row>
            <Row label={t("pages.provider_collections.show.amount")}>
              <span className="text-lg font-semibold">
                {formatMoney(account.amount)}
              </span>
            </Row>
          </dl>
        </Section>

        <Section title={t("pages.provider_collections.show.orders")}>
          {orders.length === 0 ? (
            <p className="text-muted-foreground text-sm">
              {t("pages.provider_collections.show.orders_empty")}
            </p>
          ) : (
            <div className="grid gap-4 md:grid-cols-2">
              {orders.map((order) => (
                <ListItemCard key={order.id}>
                  <CardContent className="grid gap-1">
                    <div className="flex items-baseline justify-between gap-4">
                      <p>
                        {order.menu_name}{" "}
                        <span className="text-muted-foreground font-normal">
                          {t("pages.provider_collections.show.quantity", {
                            count: order.amount ?? 0,
                          })}
                        </span>
                      </p>
                      <p className="font-semibold">
                        {formatMoney(amountOf(order))}
                      </p>
                    </div>
                    <p className="text-muted-foreground text-xs">
                      {order.consumer_name} ·{" "}
                      {order.delivery_date ??
                        t("pages.provider_collections.show.no_date")}
                    </p>
                  </CardContent>
                </ListItemCard>
              ))}
            </div>
          )}
        </Section>

        <Section title={t("pages.provider_collections.show.payments")}>
          {payments.length === 0 ? (
            <p className="text-muted-foreground text-sm">
              {t("pages.provider_collections.show.payments_empty")}
            </p>
          ) : (
            <dl className="grid gap-2 text-sm">
              {payments.map((payment) => (
                <Row key={payment.id} label={payment.date}>
                  <StatusBadge status={payment.status} kind="payment" />
                </Row>
              ))}
            </dl>
          )}
        </Section>
      </PageContainer>
    </AppLayout>
  )
}
