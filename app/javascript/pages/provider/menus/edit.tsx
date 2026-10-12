import { Head } from "@inertiajs/react"

import NewMenuForm from "@/components/menus/new-menu-form"
import PageContainer from "@/components/page-container"
import AppLayout from "@/layouts/app-layout"
import { providerMenus as menusRoutes } from "@/routes"
import type { BreadcrumbItem, ProviderMenusEdit } from "@/types"

export default function Edit(props: ProviderMenusEdit) {
  const { menu, saved_menu_id: savedMenuId, return_to: returnTo } = props

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: "Publicar menú",
      href: returnTo,
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
