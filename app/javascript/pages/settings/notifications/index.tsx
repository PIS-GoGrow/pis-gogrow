import { Head, router } from "@inertiajs/react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import { Switch } from "@/components/ui/switch"
import AppLayout from "@/layouts/app-layout"
import SettingsLayout from "@/layouts/settings/layout"
import { settingsNotifications } from "@/routes"
import type { BreadcrumbItem, SettingsNotificationsIndex } from "@/types"

export default function Notifications({
  notification_configurations,
  subscribed_keys,
}: SettingsNotificationsIndex) {
  const { t } = useTranslation()

  const [loading, setLoading] = useState(false)

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.settings.password.title"),
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

      <SettingsLayout>
        <div>
          <h1 className="text-lg">Notificaciones</h1>
          <p className="text-muted-foreground">
            Configurá qué alertas querés recibir
          </p>
          <div className="mt-3 grid gap-2">
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
        </div>
      </SettingsLayout>
    </AppLayout>
  )
}
