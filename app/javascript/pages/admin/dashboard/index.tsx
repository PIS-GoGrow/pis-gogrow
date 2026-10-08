import { Head, usePage } from "@inertiajs/react"
import { ChevronRight, Info } from "lucide-react"
import { useTranslation } from "react-i18next"

import HeadingSmall from "@/components/heading-small"
import NotificationBanners from "@/components/notification-banners"
import PageContainer from "@/components/page-container"
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import AppLayout from "@/layouts/app-layout"
import type { AdminDashboardIndex } from "@/types/serializers"

export default function AdminDashboard({
  today,
  payment_month,
}: AdminDashboardIndex) {
  const { t } = useTranslation()
  const { auth } = usePage().props
  const title = t("pages.admin.dashboard.title")
  const firstName = auth.user.name.split(" ")[0]
  return (
    <AppLayout>
      <Head title={title} />

      <PageContainer
        title={t("pages.admin.dashboard.greeting", { name: firstName })}
        description={today}
        titleVariant="prominent"
        compactHeading
      >
        <NotificationBanners />

        <div className="grid gap-4 lg:grid-cols-2 lg:gap-8">
          <Alert role="status" className="lg:col-span-2">
            <Info aria-hidden="true" />
            <AlertTitle>{t("pages.admin.dashboard.alert.title")}</AlertTitle>
            <AlertDescription>
              {t("pages.admin.dashboard.alert.pending")}
            </AlertDescription>
          </Alert>

          <Card className="bg-muted/60 h-fit gap-4 rounded-lg py-4 shadow-none">
            <CardHeader className="grid-cols-[1fr_auto] grid-rows-1 items-center px-4">
              <CardDescription>
                {t("pages.admin.dashboard.consumption.title")}
              </CardDescription>
              <Badge variant="secondary" className="bg-background font-normal">
                {t("pages.admin.dashboard.this_month")}
              </Badge>
            </CardHeader>
            <CardContent className="space-y-4 px-4">
              <p className="text-2xl font-semibold tracking-tight">
                {t("pages.admin.dashboard.coming_soon")}
              </p>
              <div className="bg-border h-2 rounded-full" aria-hidden="true" />
              <div className="grid grid-cols-2 gap-2">
                <PendingMetric
                  label={t("pages.admin.dashboard.consumption.participation")}
                />
                <PendingMetric
                  label={t("pages.admin.dashboard.consumption.spending")}
                />
              </div>
              <Button
                type="button"
                className="w-full cursor-pointer bg-neutral-900 text-white hover:bg-neutral-700 dark:bg-neutral-100 dark:text-neutral-900 dark:hover:bg-neutral-300"
              >
                {t("pages.admin.dashboard.consumption.view_detail")}
              </Button>
            </CardContent>
          </Card>

          <div className="grid content-start gap-8">
            <PendingSection
              id="admin-payments-title"
              title={t("pages.admin.dashboard.payments.title", {
                month: payment_month,
              })}
              description={t("pages.admin.dashboard.payments.pending")}
              actionLabel={t("pages.admin.dashboard.payments.view")}
            />
            <PendingSection
              id="admin-debts-title"
              title={t("pages.admin.dashboard.debts.title")}
              description={t("pages.admin.dashboard.debts.pending")}
              actionLabel={t("pages.admin.dashboard.debts.view")}
            />
          </div>
        </div>
      </PageContainer>
    </AppLayout>
  )
}

function PendingMetric({ label }: { label: string }) {
  const { t } = useTranslation()

  return (
    <div className="bg-background rounded-xl border px-3 py-2.5">
      <p className="text-muted-foreground text-sm">{label}</p>
      <p className="mt-1 text-xl font-semibold">
        {t("pages.admin.dashboard.pending_value")}
      </p>
    </div>
  )
}

function PendingSection({
  id,
  title,
  description,
  actionLabel,
}: {
  id: string
  title: string
  description: string
  actionLabel: string
}) {
  const { t } = useTranslation()

  return (
    <section aria-labelledby={id} className="space-y-3">
      <div className="flex items-center justify-between">
        <div id={id}>
          <HeadingSmall title={title} />
        </div>
        <Button
          type="button"
          variant="ghost"
          size="icon-sm"
          aria-label={actionLabel}
          className="group cursor-pointer"
        >
          <ChevronRight
            className="size-4 transition-transform group-hover:translate-x-0.5"
            aria-hidden="true"
          />
        </Button>
      </div>
      <Card className="min-h-28 justify-center gap-1 rounded-lg py-4 shadow-none">
        <CardHeader className="px-4">
          <CardTitle className="text-base">
            {t("pages.admin.dashboard.coming_soon")}
          </CardTitle>
        </CardHeader>
        <CardContent className="px-4">
          <p className="text-muted-foreground text-sm">{description}</p>
        </CardContent>
      </Card>
    </section>
  )
}
