import { Head } from "@inertiajs/react"
import { useTranslation } from "react-i18next"

import AvailableMenuCard from "@/components/menus/available-menu-card"
import AppLayout from "@/layouts/app-layout"
import { consumerMenus } from "@/routes"
import type { BreadcrumbItem, ConsumerMenusShow } from "@/types"

export default function Show({ menu }: ConsumerMenusShow) {
  const { t } = useTranslation()

  const breadcrumbs: BreadcrumbItem[] = [
    { title: t("nav.menus"), href: consumerMenus.index().url },
    { title: menu.name ?? "", href: consumerMenus.show(menu.id).url },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={`${t("nav.menus")} | ${menu.name}`} />

      <div className="mx-auto w-full max-w-150 p-5">
        <AvailableMenuCard menu={menu} />
      </div>
    </AppLayout>
  )
}
