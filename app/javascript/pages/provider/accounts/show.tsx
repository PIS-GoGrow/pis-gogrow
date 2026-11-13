import { Head, Link, router, usePage } from "@inertiajs/react"
import { ChevronRight, CircleAlert, LogOut } from "lucide-react"
import { useTranslation } from "react-i18next"

import PageContainer from "@/components/page-container"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Button } from "@/components/ui/button"
import { useInitials } from "@/hooks/use-initials"
import AppLayout from "@/layouts/app-layout"
import {
  providerAccount,
  providerDeliveries,
  providerOperationalSettings,
  providerPaymentDetails,
  sessions,
  settingsNotifications,
  settingsProfiles,
} from "@/routes"
import type { BreadcrumbItem } from "@/types"
import type { ProviderAccountsShow } from "@/types/serializers/ProviderAccountsShow"

export default function ProviderAccount({
  incomplete_sections,
}: ProviderAccountsShow) {
  const { t } = useTranslation()
  const { auth } = usePage().props
  const getInitials = useInitials()
  const account = "pages.provider_accounts.show"

  const breadcrumbs: BreadcrumbItem[] = [
    { title: t(`${account}.title`), href: providerAccount().url },
  ]
  const settings = [
    {
      section: "profile",
      title: t(`${account}.profile`),
      description: t(`${account}.profile_description`),
      href: settingsProfiles.show().url,
    },
    {
      section: "payment_details",
      title: t(`${account}.payment_details`),
      description: t(`${account}.payment_details_description`),
      href: providerPaymentDetails.show().url,
    },
    {
      section: "operational_settings",
      title: t(`${account}.operational_settings`),
      description: t(`${account}.operational_settings_description`),
      href: providerOperationalSettings.show().url,
    },
    {
      section: "deliveries",
      title: t(`${account}.deliveries`),
      description: t(`${account}.deliveries_description`),
      href: providerDeliveries.show().url,
    },
    {
      section: "notifications",
      title: t(`${account}.notifications`),
      description: t(`${account}.notifications_description`),
      href: settingsNotifications.index().url,
    },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t(`${account}.title`)} />

      <PageContainer
        title={t(`${account}.title`)}
        titleVariant="prominent"
        actions={
          <Button
            variant="ghost"
            className="gap-1.5 px-1 font-semibold text-red-700 hover:text-red-700 has-[>svg]:px-1 dark:text-red-400 dark:hover:text-red-400"
            asChild
          >
            <Link
              href={sessions.destroy(auth.session.id)}
              as="button"
              onClick={() => router.flushAll()}
            >
              <LogOut className="size-4" aria-hidden="true" />
              {t(`${account}.sign_out`)}
            </Link>
          </Button>
        }
      >
        <div className="flex items-center gap-3 border-b pb-6">
          <Avatar size="lg">
            <AvatarImage src={auth.user.avatar} alt={auth.user.name} />
            <AvatarFallback>{getInitials(auth.user.name)}</AvatarFallback>
          </Avatar>
          <div className="min-w-0">
            <p className="truncate text-base font-semibold">{auth.user.name}</p>
            <p className="text-muted-foreground truncate text-sm">
              {auth.user.email}
            </p>
          </div>
        </div>

        <section aria-labelledby="provider-settings-title">
          <h3 id="provider-settings-title" className="mb-3 text-xl font-bold">
            {t(`${account}.settings`)}
          </h3>
          <div className="border-t">
            {settings.map(({ section, title, description, href }) => {
              const incomplete = incomplete_sections.includes(section)
              const content = (
                <>
                  <span className="min-w-0 flex-1 text-left">
                    <span className="block text-base font-medium">{title}</span>
                    <span className="text-muted-foreground block text-sm">
                      {description}
                    </span>
                  </span>
                  {incomplete && (
                    <CircleAlert
                      className="size-5 shrink-0 text-amber-500"
                      aria-label={t(`${account}.incomplete`)}
                    />
                  )}
                  <ChevronRight
                    className="text-muted-foreground size-5 shrink-0"
                    aria-hidden="true"
                  />
                </>
              )
              const className =
                "hover:bg-accent/50 flex w-full cursor-pointer items-center gap-4 border-b px-1 py-5 transition-colors"

              return (
                <Link key={title} href={href} prefetch className={className}>
                  {content}
                </Link>
              )
            })}
          </div>
        </section>
      </PageContainer>
    </AppLayout>
  )
}
