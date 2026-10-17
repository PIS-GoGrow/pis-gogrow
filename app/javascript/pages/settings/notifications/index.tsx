import { Head, router, usePage } from "@inertiajs/react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import { Switch } from "@/components/ui/switch"
import AppLayout from "@/layouts/app-layout"
import SettingsPageLayout from "@/layouts/settings/page-layout"
import { settingsNotifications } from "@/routes"
import type { BreadcrumbItem, SettingsNotificationsIndex } from "@/types"

export default function Notifications({
  notification_configurations,
  subscribed_keys,
}: SettingsNotificationsIndex) {
  const { t } = useTranslation()
  const { auth } = usePage().props

  const [loading, setLoading] = useState(false)

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.settings.notifications.title"),
      href: settingsNotifications.index().url,
    },
  ]

  function changeSubscription(id: number, subscribe: boolean) {
    setLoading(true)
    router.patch(
      settingsNotifications.update(id).url,
      { subscribe: subscribe },
      {
        preserveScroll: true,
        preserveState: true,
        onFinish: () => setLoading(false),
      },
    )
  }

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={breadcrumbs[breadcrumbs.length - 1].title} />

      <SettingsPageLayout
        title={t("pages.settings.notifications.heading")}
        description={t("pages.settings.notifications.description")}
        adminBackLabel={t("pages.settings.notifications.back")}
      >
        {auth.session.role === "admin" && (
          <div className="space-y-1">
            <h2 className="text-base font-semibold">
              {t("pages.settings.notifications.preferences_heading")}
            </h2>
            <p className="text-muted-foreground text-sm">
              {t("pages.settings.notifications.preferences_description")}
            </p>
          </div>
        )}

        <div className="grid gap-2">
          {notification_configurations.map(
            ({ id, key, title, description }) => {
              const subscribed = subscribed_keys.includes(key)

              return (
                <div key={key} className="flex border-b py-3">
                  <div className="w-[90%] pr-5">
                    <h2>{title}</h2>
                    <p className="text-muted-foreground text-sm">
                      {description}
                    </p>
                  </div>
                  <Switch
                    aria-label={title}
                    checked={subscribed}
                    disabled={loading}
                    onCheckedChange={() => {
                      changeSubscription(id, !subscribed)
                    }}
                    className="data-[state=checked]:bg-green-600 dark:data-[state=checked]:bg-green-600"
                  />
                </div>
              )
            },
          )}
        </div>
      </SettingsPageLayout>
    </AppLayout>
  )
}
