import { Head, Link } from "@inertiajs/react"
import { ChevronLeft } from "lucide-react"
import { useTranslation } from "react-i18next"

import NewMenuForm from "@/components/menus/new-menu-form"
import { Button } from "@/components/ui/button"
import AppLayout from "@/layouts/app-layout"
import { providerMenus as menusRoutes } from "@/routes"
import type { BreadcrumbItem, ProviderMenusEdit } from "@/types"

export default function Edit(props: ProviderMenusEdit) {
  const { t } = useTranslation()
  const key = "pages.provider_menus.edit"
  const { menu, saved_menu_id: savedMenuId, return_to: returnTo } = props

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.schedules.index.title"),
      href: returnTo,
    },
    {
      title: t(`${key}.title`),
      href: menusRoutes.edit(savedMenuId).url,
    },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={`${t(`${key}.title`)} | ${menu.name}`} />

      <div className="mx-auto w-full max-w-xl p-5">
        <div className="relative mb-6 flex h-9 items-center justify-center">
          <Button
            variant="ghost"
            size="icon"
            className="absolute left-0 -ml-2"
            asChild
          >
            <Link href={returnTo} aria-label={t(`${key}.back`)}>
              <ChevronLeft aria-hidden="true" className="size-5" />
            </Link>
          </Button>
          <h1 className="text-base font-semibold">{t(`${key}.title`)}</h1>
        </div>

        <NewMenuForm menu={menu} edit={props} />
      </div>
    </AppLayout>
  )
}
