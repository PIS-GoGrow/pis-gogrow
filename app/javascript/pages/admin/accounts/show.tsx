import { Head, Link, router, usePage } from "@inertiajs/react"
import { ChevronRight, LogOut } from "lucide-react"
import { useTranslation } from "react-i18next"

import PageContainer from "@/components/page-container"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Button } from "@/components/ui/button"
import { useInitials } from "@/hooks/use-initials"
import AppLayout from "@/layouts/app-layout"
import {
  adminAccount,
  adminBenefitConfigurations,
  adminPreferences,
  sessions,
  settingsNotifications,
} from "@/routes"
import type { BreadcrumbItem } from "@/types"

export default function AdminAccount() {
  const { t } = useTranslation()
  const { auth } = usePage().props
  const getInitials = useInitials()
  const account = "pages.admin.account"

  const breadcrumbs: BreadcrumbItem[] = [
    { title: t(`${account}.title`), href: adminAccount().url },
  ]
  const primarySettings = [
    {
      title: t(`${account}.subsidies`),
      description: t(`${account}.subsidies_description`),
      href: adminBenefitConfigurations.index().url,
    },
    {
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

        <section aria-labelledby="admin-settings-title">
          <h3 id="admin-settings-title" className="mb-3 text-xl font-bold">
            {t(`${account}.settings`)}
          </h3>
          <div className="border-t">
            {primarySettings.map(({ title, description, href }) => (
              <AccountLink
                key={title}
                title={title}
                description={description}
                href={href}
              />
            ))}
          </div>
        </section>

        <section aria-labelledby="admin-more-settings-title" className="mt-4">
          <h3
            id="admin-more-settings-title"
            className="mb-3 text-base font-semibold"
          >
            {t(`${account}.more_options`)}
          </h3>
          <div className="border-t">
            <AccountLink
              title={t(`${account}.preferences`)}
              description={t(`${account}.preferences_description`)}
              href={adminPreferences.show().url}
            />
          </div>
        </section>
      </PageContainer>
    </AppLayout>
  )
}

interface AccountLinkProps {
  title: string
  description: string
  href: string
}

function AccountLink({ title, description, href }: AccountLinkProps) {
  return (
    <Link
      href={href}
      prefetch
      className="hover:bg-accent/50 flex w-full cursor-pointer items-center gap-4 border-b px-1 py-5 transition-colors"
    >
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
    </Link>
  )
}
