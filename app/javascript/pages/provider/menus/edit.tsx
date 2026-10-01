import { Head } from "@inertiajs/react"

import NewMenuForm from "@/components/menus/new-menu-form"
import PageContainer from "@/components/page-container"
import AppLayout from "@/layouts/app-layout"
import { providerMenus as menusRoutes } from "@/routes"
import type { BreadcrumbItem, ProviderMenusEdit } from "@/types"

export default function Edit(props: ProviderMenusEdit) {
  const { menu, saved_menu_id: savedMenuId } = props

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: "Platos",
      href: menusRoutes.index().url,
    },
    {
      title: menu.name ?? "Plato",
      href: menusRoutes.show(savedMenuId).url,
    },
    {
      title: "Editar",
      href: menusRoutes.edit(savedMenuId).url,
    },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={`Editar | ${menu.name}`} />

      <PageContainer eyebrow="Editar plato" title={menu.name ?? "Plato"}>
        <NewMenuForm menu={menu} edit={props} />
      </PageContainer>
    </AppLayout>
  )
}
