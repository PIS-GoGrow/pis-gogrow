import { Head } from "@inertiajs/react"
import { useTranslation } from "react-i18next"

import AppearanceTabs from "@/components/appearance-tabs"
import AppLayout from "@/layouts/app-layout"
import SettingsPageLayout from "@/layouts/settings/page-layout"
import { adminPreferences, settingsAppearance } from "@/routes"
import type { BreadcrumbItem } from "@/types"

export default function Appearance() {
  const { t } = useTranslation()

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.settings.appearance.title"),
      href: settingsAppearance().url,
    },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={breadcrumbs[breadcrumbs.length - 1].title} />

      <SettingsPageLayout
        title={t("pages.settings.appearance.title")}
        description={t("pages.settings.appearance.description")}
        adminBackHref={adminPreferences.show().url}
        adminBackLabel={t("pages.settings.appearance.back")}
      >
        <AppearanceTabs />
      </SettingsPageLayout>
    </AppLayout>
  )
}
