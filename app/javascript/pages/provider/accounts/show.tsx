import { Head, Link, router, usePage } from "@inertiajs/react"
import { ChevronRight, LogOut } from "lucide-react"
import { useTranslation } from "react-i18next"

import PageContainer from "@/components/page-container"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Button } from "@/components/ui/button"
import { useInitials } from "@/hooks/use-initials"
import AppLayout from "@/layouts/app-layout"
import {
  providerAccount,
  providerOperationalSettings,
  sessions,
} from "@/routes"
import type { BreadcrumbItem } from "@/types"

export default function ProviderAccount() {
  const { t } = useTranslation()
  const { auth } = usePage().props
  const getInitials = useInitials()
  const account = "pages.provider_accounts.show"

  const breadcrumbs: BreadcrumbItem[] = [
    { title: t(`${account}.title`), href: providerAccount().url },
  ]
  const settings = [
    {
      title: t(`${account}.payment_details`),
      description: t(`${account}.payment_details_description`),
    },
    {
      title: t(`${account}.operational_settings`),
      description: t(`${account}.operational_settings_description`),
      href: providerOperationalSettings.show().url,
    },
    {
      title: t(`${account}.deliveries`),
      description: t(`${account}.deliveries_description`),
    },
    {
      title: t(`${account}.notifications`),
      description: t(`${account}.notifications_description`),
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
            {settings.map(({ title, description, href }) => {
              const content = (
                <>
                  <span className="min-w-0 flex-1 text-left">
                    <span className="block text-base font-medium">{title}</span>
                    <span className="text-muted-foreground block text-sm">
                      {description}
                    </span>
                  </span>
                  <ChevronRight
                    className="text-muted-foreground size-5 shrink-0"
                    aria-hidden="true"
                  />
                </>
              )
              const className =
                "hover:bg-accent/50 flex w-full cursor-pointer items-center gap-4 border-b px-1 py-5 transition-colors"

              return href ? (
                <Link key={title} href={href} prefetch className={className}>
                  {content}
                </Link>
              ) : (
                <button key={title} type="button" className={className}>
                  {content}
                </button>
              )
            })}
          </div>
        </section>
      </PageContainer>
    </AppLayout>
  )
}
