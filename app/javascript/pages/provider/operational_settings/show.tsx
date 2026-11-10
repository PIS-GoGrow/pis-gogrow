import { Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"
import { useTranslation } from "react-i18next"

import PageContainer from "@/components/page-container"
import ClosingTimeSection from "@/components/provider/closing-time-section"
import ClosuresSection from "@/components/provider/closures-section"
import { Button } from "@/components/ui/button"
import AppLayout from "@/layouts/app-layout"
import { providerAccount, providerOperationalSettings } from "@/routes"
import type { BreadcrumbItem } from "@/types"
import type { ProviderOperationalSettingsShow } from "@/types/serializers/ProviderOperationalSettingsShow"

export default function OperationalSettings({
  provider,
  closures,
  today,
  order_deadline_passed_today,
}: ProviderOperationalSettingsShow) {
  const { t } = useTranslation()
  const page = "pages.provider_operational_settings.show"

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.provider_accounts.show.title"),
      href: providerAccount().url,
    },
    { title: t(`${page}.title`), href: providerOperationalSettings.show().url },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t(`${page}.title`)} />

      <PageContainer
        title={t(`${page}.title`)}
        titleVariant="prominent"
        description={t(`${page}.description`)}
        back={
          <Button variant="ghost" size="icon" asChild>
            <Link href={providerAccount().url} aria-label={t(`${page}.back`)}>
              <ArrowLeft aria-hidden="true" />
            </Link>
          </Button>
        }
      >
        <div className="grid gap-4 lg:grid-cols-2">
          <ClosingTimeSection
            orderDeadline={provider.order_deadline}
            orderDeadlinePassedToday={order_deadline_passed_today}
          />
          <ClosuresSection closures={closures} today={today} />
        </div>
      </PageContainer>
    </AppLayout>
  )
}
