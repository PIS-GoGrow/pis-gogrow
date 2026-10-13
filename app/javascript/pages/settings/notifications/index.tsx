import { Transition } from "@headlessui/react"
import { Form, Head, router } from "@inertiajs/react"
import { useTranslation } from "react-i18next"
import { useState } from "react"

import HeadingSmall from "@/components/heading-small"
import { Button } from "@/components/ui/button"
import {
  Field,
  FieldError,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import AppLayout from "@/layouts/app-layout"
import SettingsLayout from "@/layouts/settings/layout"
import { settingsNotifications } from "@/routes"
import type { SettingsNotifications } from "@/types"
import { Switch } from "@/components/ui/switch"

export default function Notifications({
  notification_configurations,
  subscribed_keys,
}: SettingsNotifications) {
  const { t } = useTranslation()

  const [loading, setLoading] = useState(false)

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.settings.password.title"),
      href: settingsNotifications.index().url,
    },
  ]

  async function changeSubscription(id: number, subscribe: boolean) {
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
        <div className="grid gap-2">
          {notification_configurations.map(
            ({ id, key, title, description }) => {
              const subscribed = subscribed_keys.includes(key)

              return (
                <div key={key} className="flex border-b py-3">
                  <div className="w-[90%] pr-5">
                    <h1>{title}</h1>
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
      </SettingsLayout>
    </AppLayout>
  )
}
