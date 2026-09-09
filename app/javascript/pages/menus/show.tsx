import { Head } from "@inertiajs/react"
import { useState } from "react"

import { menus as menusRoutes } from "@/routes"
import type { Menu } from "@/types"
import type { BreadcrumbItem } from "@/types"
import MenuCard from "@/components/menus/menu-card"
import DeleteMenuDialog from "@/components/menus/delete-menu-dialog"
import AppLayout from "@/layouts/app-layout"
import { Dialog } from "@/components/ui/dialog"

interface MenuProps {
  menu: Menu
}

export default function Show({ menu }: MenuProps) {
  const [deletingMenu, setDeletingMenu] = useState<{
    id: number | null
    name: string
  }>({ id: null, name: "" })

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: "Platos",
      href: menusRoutes.index().url,
    },
    {
      title: menu.name,
      href: menusRoutes.show(menu.id).url,
    },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={ "Platos | " + menu.name} />
      <DeleteMenuDialog name={deletingMenu.name} id={deletingMenu.id}>
        <div class="w-150 mx-auto mt-5">
          <MenuCard menu={menu} showLink={false} setDeletingMenu={setDeletingMenu}/>
        </div>
      </DeleteMenuDialog>
    </AppLayout>
  )
}
