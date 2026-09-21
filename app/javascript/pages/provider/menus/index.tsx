import { Head } from "@inertiajs/react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import CreateMenuDialog from "@/components/menus/create-menu-dialog"
import DeleteMenuDialog from "@/components/menus/delete-menu-dialog"
import MenuCard from "@/components/menus/menu-card"
import PageContainer from "@/components/page-container"
import { Button } from "@/components/ui/button"
import { DialogTrigger } from "@/components/ui/dialog"
import {
  Empty,
  EmptyContent,
  EmptyDescription,
  EmptyHeader,
  EmptyTitle,
} from "@/components/ui/empty"
import AppLayout from "@/layouts/app-layout"
import { providerMenus as menusRoutes } from "@/routes"
import type { Menu } from "@/types"
import type { BreadcrumbItem } from "@/types"

interface MenuProps {
  menus: Menu[]
}

export default function Index({ menus }: MenuProps) {
  const [deletingMenu, setDeletingMenu] = useState<{
    id: number | null
    name: string
  }>({ id: null, name: "" })

  const { t } = useTranslation()

  const menusJSX = menus.map((menu: Menu) => (
    <MenuCard
      key={menu.id}
      menu={menu}
      showLink={true}
      setDeletingMenu={setDeletingMenu}
    />
  ))

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: "Platos",
      href: menusRoutes.index().url,
    },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title="Mis Platos" />

      <CreateMenuDialog>
        {/* Agregamos un diálogo al lado del título para mostrar el formulario de crear platos */}
        <PageContainer
          eyebrow="Vista de todos los platos"
          title="Mis platos"
          actions={
            <DialogTrigger className="ml-auto" asChild>
              <Button>Agregar plato</Button>
            </DialogTrigger>
          }
        >
          {/* Listamos los platos y creamos un diálogo para confirmar si eliminarlos. */}
          {menus.length == 0 ? (
            <Empty>
              <EmptyHeader>
                <EmptyTitle>No hay platos aún</EmptyTitle>
                <EmptyDescription>
                  No creaste ningún plato todavía. Creá el primero ahora para
                  poder publicar tu menú.
                </EmptyDescription>
                <EmptyContent>
                  <DialogTrigger asChild>
                    <Button>Agregar plato</Button>
                  </DialogTrigger>
                </EmptyContent>
              </EmptyHeader>
            </Empty>
          ) : (
            <DeleteMenuDialog name={deletingMenu.name} id={deletingMenu.id}>
              <div className="grid grid-cols-2 gap-2">{menusJSX}</div>
            </DeleteMenuDialog>
          )}
        </PageContainer>
      </CreateMenuDialog>
    </AppLayout>
  )
}
