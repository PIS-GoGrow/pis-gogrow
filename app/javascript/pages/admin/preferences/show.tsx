import { Head, Link } from "@inertiajs/react"
import { ArrowLeft, ChevronRight } from "lucide-react"
import { useTranslation } from "react-i18next"

import PageContainer from "@/components/page-container"
import { Button } from "@/components/ui/button"
import AppLayout from "@/layouts/app-layout"
import {
  adminAccount,
  adminPreferences,
  settingsAppearance,
  settingsProfiles,
} from "@/routes"
import type { BreadcrumbItem } from "@/types"

export default function AdminPreferences() {
  const { t } = useTranslation()
  const page = "pages.admin.preferences"

  const breadcrumbs: BreadcrumbItem[] = [
    { title: t("pages.admin.account.title"), href: adminAccount().url },
    { title: t(`${page}.title`), href: adminPreferences.show().url },
  ]
  const options = [
    {
      title: t(`${page}.profile`),
      description: t(`${page}.profile_description`),
      href: settingsProfiles.show().url,
    },
    {
      title: t(`${page}.appearance`),
      description: t(`${page}.appearance_description`),
      href: settingsAppearance().url,
    },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t(`${page}.title`)} />

      <PageContainer
        title={t(`${page}.title`)}
        titleVariant="prominent"
        description={t(`${page}.description`)}
        back={
          <Button variant="ghost" size="icon" asChild>
            <Link href={adminAccount()} aria-label={t(`${page}.back`)}>
              <ArrowLeft aria-hidden="true" />
            </Link>
          </Button>
        }
      >
        <div className="max-w-xl border-t">
          {options.map(({ title, description, href }) => (
            <Link
              key={href}
              href={href}
              prefetch
              className="hover:bg-accent/50 flex items-center gap-4 border-b px-1 py-5 transition-colors"
            >
              <span className="min-w-0 flex-1">
                <span className="block font-medium">{title}</span>
                <span className="text-muted-foreground block text-sm">
                  {description}
                </span>
              </span>
              <ChevronRight
                className="text-muted-foreground size-5 shrink-0"
                aria-hidden="true"
              />
            </Link>
          ))}
        </div>
      </PageContainer>
    </AppLayout>
  )
}
