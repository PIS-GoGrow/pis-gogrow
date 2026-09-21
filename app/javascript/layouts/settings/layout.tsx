import { Link, usePage } from "@inertiajs/react"
import type { PropsWithChildren } from "react"
import { useTranslation } from "react-i18next"

import { ConsumerMobileNav } from "@/components/consumer/consumer-mobile-nav"
import Heading from "@/components/heading"
import { Button } from "@/components/ui/button"
import { Separator } from "@/components/ui/separator"
import { cn } from "@/lib/utils"
import {
  settingsAppearance,
  settingsEmails,
  settingsPasswords,
  settingsProfiles,
  settingsSessions,
} from "@/routes"
import type { NavItem } from "@/types"

export default function SettingsLayout({ children }: PropsWithChildren) {
  const { t } = useTranslation()
  const { url, props } = usePage()
  const isConsumer = props.auth.session.role === "consumer"

  const sidebarNavItems: NavItem[] = [
    {
      title: t("nav.settings.profile"),
      href: settingsProfiles.show().url,
      icon: null,
    },
    {
      title: t("nav.settings.email"),
      href: settingsEmails.show().url,
      icon: null,
    },
    {
      title: t("nav.settings.password"),
      href: settingsPasswords.show().url,
      icon: null,
    },
    {
      title: t("nav.settings.sessions"),
      href: settingsSessions.index().url,
      icon: null,
    },
    {
      title: t("nav.settings.appearance"),
      href: settingsAppearance().url,
      icon: null,
    },
  ]

  return (
    <div className="px-4 py-6 pb-24 md:pb-6">
      <Heading
        title={t("components.settings_layout.title")}
        description={t("components.settings_layout.description")}
      />

      <div className="flex flex-col space-y-8 lg:flex-row lg:space-y-0 lg:space-x-12">
        <aside className="w-full max-w-xl lg:w-48">
          <nav className="flex flex-col space-y-1 space-x-0">
            {sidebarNavItems.map((item, index) => (
              <Button
                key={`${item.href}-${index}`}
                size="sm"
                variant="ghost"
                asChild
                className={cn("w-full justify-start", {
                  "bg-muted": url === item.href,
                })}
              >
                <Link href={item.href}>
                  {item.icon && <item.icon className="h-4 w-4" />}
                  {item.title}
                </Link>
              </Button>
            ))}
          </nav>
        </aside>

        <Separator className="my-6 md:hidden" />

        <div className="flex-1 md:max-w-2xl">
          <section className="max-w-xl space-y-12">{children}</section>
        </div>
      </div>

      {isConsumer && <ConsumerMobileNav />}
    </div>
  )
}
