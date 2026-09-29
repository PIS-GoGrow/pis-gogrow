import { Head } from "@inertiajs/react"
import { useTranslation } from "react-i18next"

import PageContainer from "@/components/page-container"
import AppLayout from "@/layouts/app-layout"
import { providerDashboard } from "@/routes"
import type { BreadcrumbItem } from "@/types"

export default function ProviderDashboard() {
  const { t } = useTranslation()

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.provider_dashboard.index.title"),
      href: providerDashboard.index().url,
    },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t("pages.provider_dashboard.index.title")} />

      <PageContainer
        eyebrow={t("pages.provider_dashboard.index.eyebrow")}
        title={t("pages.provider_dashboard.index.title")}
        description={t("pages.provider_dashboard.index.description")}
      >
        {null}
      </PageContainer>
    </AppLayout>
  )
}
