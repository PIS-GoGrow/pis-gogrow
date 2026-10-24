import { Head, Link, usePage } from "@inertiajs/react"
import { useTranslation } from "react-i18next"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import AppLayout from "@/layouts/app-layout"
import SettingsPageLayout from "@/layouts/settings/page-layout"
import { formatShortDateTime } from "@/lib/dates"
import { sessions as sessionsRoutes, settingsSessions } from "@/routes"
import type { BreadcrumbItem, Session } from "@/types"

interface SessionsProps {
  sessions: Session[]
}

export default function Sessions({ sessions }: SessionsProps) {
  const { t } = useTranslation()

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.settings.sessions.title"),
      href: settingsSessions.index().url,
    },
  ]

  const { auth } = usePage().props

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={breadcrumbs[breadcrumbs.length - 1].title} />

      <SettingsPageLayout
        title={t("pages.settings.sessions.title")}
        description={t("pages.settings.sessions.description")}
      >
        <div className="space-y-4">
          {sessions.map((session) => (
            <div
              key={session.id}
              className="flex flex-col space-y-2 rounded-lg border p-4"
            >
              <div className="flex items-center justify-between">
                <div className="space-y-1">
                  <p className="font-medium">
                    {session.user_agent}
                    {session.id === auth.session.id && (
                      <Badge variant="secondary" className="ml-2">
                        {t("pages.settings.sessions.current")}
                      </Badge>
                    )}
                  </p>
                  <p className="text-muted-foreground text-sm">
                    {t("pages.settings.sessions.ip", {
                      address: session.ip_address,
                    })}
                  </p>
                  <p className="text-muted-foreground text-sm">
                    {t("pages.settings.sessions.active_since", {
                      time: formatShortDateTime(session.created_at),
                    })}
                  </p>
                </div>
                {session.id !== auth.session.id && (
                  <Button variant="destructive" asChild>
                    <Link href={sessionsRoutes.destroy(session.id)} as="button">
                      {t("pages.settings.sessions.log_out")}
                    </Link>
                  </Button>
                )}
              </div>
            </div>
          ))}
        </div>
      </SettingsPageLayout>
    </AppLayout>
  )
}
