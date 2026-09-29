import { Head } from "@inertiajs/react"

import PageContainer from "@/components/page-container"
import AppLayout from "@/layouts/app-layout"
import { providerMenus as menusRoutes } from "@/routes"
import type { Menu } from "@/types"
import type { BreadcrumbItem } from "@/types"
import NewMenuForm from "@/components/menus/new-menu-form"

interface EditMenuProps {
  menu: Menu
}

export default function Edit({ menu }: EditMenuProps) {
  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: "Platos",
      href: menusRoutes.index().url,
    },
    {
      title: menu.name ?? "Plato",
      href: menusRoutes.show(menu.id).url,
    },
    {
      title: "Editar",
      href: menusRoutes.edit(menu.id).url,
    },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={`Editar | ${menu.name}`} />

      <PageContainer eyebrow="Editar plato" title={menu.name ?? "Plato"}>
        <NewMenuForm menu={menu} />
      </PageContainer>
    </AppLayout>
  )
}
