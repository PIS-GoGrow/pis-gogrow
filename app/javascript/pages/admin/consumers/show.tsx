import { Head, Link, usePage } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"
import { useTranslation } from "react-i18next"

import StatusBadge from "@/components/status-badge"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import {
  Card,
  CardAction,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { Empty, EmptyHeader, EmptyTitle } from "@/components/ui/empty"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { useFormatters } from "@/hooks/use-formatters"
import AppLayout from "@/layouts/app-layout"
import { adminConsumers } from "@/routes"
import type {
  AdminConsumersShow,
  Benefit,
  BreadcrumbItem,
  PaymentStatus,
} from "@/types"

function EmptySection({ description }: { description: string }) {
  return (
    <Empty>
      <EmptyHeader>
        <EmptyTitle>{description}</EmptyTitle>
      </EmptyHeader>
    </Empty>
  )
}

const paymentStatusVariant: Record<PaymentStatus, "outline" | "default"> = {
  pending: "outline",
  paid: "default",
}

export default function Show({
  consumer,
  orders,
  benefits,
  debts,
  payments,
}: AdminConsumersShow) {
  const { t } = useTranslation()
  const { locale } = usePage().props
  const { formatMoney, formatDeliveryDate } = useFormatters()

  const formatMonth = (month: string) =>
    new Intl.DateTimeFormat(locale, { month: "long", year: "numeric" }).format(
      new Date(month),
    )

  const formatDate = (date: string) =>
    new Intl.DateTimeFormat(locale, { dateStyle: "medium" }).format(
      new Date(date),
    )

  const benefitTitle = (benefit: Benefit) =>
    benefit.description ??
    t("pages.admin.consumers.show.benefit_percentage", {
      percentage: benefit.percentage ?? 0,
    })

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.admin.consumers.index.title"),
      href: adminConsumers.index().url,
    },
    { title: consumer.name, href: adminConsumers.show(consumer.id).url },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={consumer.name} />

      <div className="mx-auto grid w-full max-w-3xl gap-4 p-5">
        <Button
          variant="ghost"
          size="sm"
          className="justify-self-start"
          asChild
        >
          <Link href={adminConsumers.index().url}>
            <ArrowLeft />
            {t("pages.admin.consumers.show.back")}
          </Link>
        </Button>

        <Card>
          <CardHeader>
            <CardTitle className="text-lg">{consumer.name}</CardTitle>
            <CardDescription>{consumer.email}</CardDescription>
          </CardHeader>
          <CardContent className="text-muted-foreground text-sm">
            {consumer.company_name}
            {consumer.address && <> · {consumer.address}</>}
          </CardContent>
        </Card>

        <Tabs defaultValue="orders" className="gap-4">
          <TabsList className="w-full">
            <TabsTrigger value="orders">
              {t("pages.admin.consumers.show.orders_tab")}
            </TabsTrigger>
            <TabsTrigger value="benefits">
              {t("pages.admin.consumers.show.benefits_tab")}
            </TabsTrigger>
            <TabsTrigger value="payments">
              {t("pages.admin.consumers.show.payments_tab")}
            </TabsTrigger>
            <TabsTrigger value="debts">
              {t("pages.admin.consumers.show.debts_tab")}
            </TabsTrigger>
          </TabsList>

          <TabsContent value="orders" className="grid gap-3">
            {orders.length === 0 ? (
              <EmptySection
                description={t("pages.admin.consumers.show.orders_empty")}
              />
            ) : (
              orders.map((order) => (
                <Card key={order.id} className="gap-2 py-4">
                  <CardHeader className="gap-1 px-4">
                    <CardDescription>
                      {order.provider_name ??
                        t("pages.orders.index.no_provider")}
                    </CardDescription>
                    <CardTitle className="text-base">
                      {order.menu_name ?? t("pages.orders.index.no_menu")}
                    </CardTitle>
                    <CardAction>
                      <StatusBadge status={order.status} />
                    </CardAction>
                  </CardHeader>
                  <CardContent className="flex items-baseline justify-between gap-3 px-4">
                    <p className="text-muted-foreground text-sm">
                      {order.date
                        ? formatDeliveryDate(order.date)
                        : t("pages.orders.index.no_date")}
                    </p>
                    <p className="text-sm font-medium">
                      {order.discounted_price != null
                        ? formatMoney(order.discounted_price)
                        : t("pages.orders.index.no_price")}
                    </p>
                  </CardContent>
                </Card>
              ))
            )}
          </TabsContent>

          <TabsContent value="benefits" className="grid gap-3">
            {benefits.length === 0 ? (
              <EmptySection
                description={t("pages.admin.consumers.show.benefits_empty")}
              />
            ) : (
              benefits.map((benefit) => (
                <Card key={benefit.id} className="gap-2 py-4">
                  <CardHeader className="gap-1 px-4">
                    <CardTitle className="text-base">
                      {benefitTitle(benefit)}
                    </CardTitle>
                    {benefit.due_date && (
                      <CardDescription>
                        {t("pages.admin.consumers.show.benefit_due_date", {
                          date: formatDate(benefit.due_date),
                        })}
                      </CardDescription>
                    )}
                  </CardHeader>
                  <CardContent className="px-4">
                    <p className="text-sm font-medium">
                      {benefit.amount != null
                        ? formatMoney(benefit.amount)
                        : t("pages.orders.index.no_price")}
                    </p>
                  </CardContent>
                </Card>
              ))
            )}
          </TabsContent>

          <TabsContent value="payments" className="grid gap-3">
            {payments.length === 0 ? (
              <EmptySection
                description={t("pages.admin.consumers.show.payments_empty")}
              />
            ) : (
              payments.map((payment) => (
                <Card key={payment.id} className="gap-2 py-4">
                  <CardContent className="flex items-center justify-between gap-3 px-4">
                    <p className="text-muted-foreground text-sm">
                      {formatDate(payment.created_at)}
                    </p>
                    {payment.status && (
                      <Badge variant={paymentStatusVariant[payment.status]}>
                        {t(
                          `pages.admin.consumers.payment_statuses.${payment.status}`,
                        )}
                      </Badge>
                    )}
                  </CardContent>
                </Card>
              ))
            )}
          </TabsContent>

          <TabsContent value="debts" className="grid gap-3">
            {debts.length === 0 ? (
              <EmptySection
                description={t("pages.admin.consumers.show.debts_empty")}
              />
            ) : (
              debts.map((debt) => (
                <Card key={debt.id} className="gap-2 py-4">
                  <CardContent className="flex items-center justify-between gap-3 px-4">
                    <p className="text-muted-foreground text-sm">
                      {debt.month
                        ? t("pages.admin.consumers.show.debt_month", {
                            month: formatMonth(debt.month),
                          })
                        : null}
                    </p>
                    <p className="text-sm font-medium">
                      {debt.amount != null
                        ? formatMoney(debt.amount)
                        : t("pages.orders.index.no_price")}
                    </p>
                  </CardContent>
                </Card>
              ))
            )}
          </TabsContent>
        </Tabs>
      </div>
    </AppLayout>
  )
}
