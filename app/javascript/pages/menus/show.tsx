import { Head } from "@inertiajs/react"
import { useState } from "react"

import DeleteMenuDialog from "@/components/menus/delete-menu-dialog"
import MenuCard from "@/components/menus/menu-card"
import AppLayout from "@/layouts/app-layout"
import { menus as menusRoutes } from "@/routes"
import type { Menu } from "@/types"
import type { BreadcrumbItem } from "@/types"

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
      title: menu.name ?? "Plato",
      href: menusRoutes.show(menu.id).url,
    },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={"Platos | " + menu.name} />
      <DeleteMenuDialog name={deletingMenu.name} id={deletingMenu.id}>
        <div className="mx-auto mt-5 w-150">
          <MenuCard
            menu={menu}
            showLink={false}
            setDeletingMenu={setDeletingMenu}
          />
        </div>
      </DeleteMenuDialog>
    </AppLayout>
  )
}
