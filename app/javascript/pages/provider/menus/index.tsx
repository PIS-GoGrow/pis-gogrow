import { Head, Link } from "@inertiajs/react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import DeleteMenuDialog from "@/components/menus/delete-menu-dialog"
import MenuCard from "@/components/menus/menu-card"
import PageContainer from "@/components/page-container"
import { Button } from "@/components/ui/button"
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
  const { t } = useTranslation()
  const [deletingMenu, setDeletingMenu] = useState<{
    id: number | null
    name: string
  }>({ id: null, name: "" })

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
      title: t("pages.provider_menus.index.title"),
      href: menusRoutes.index().url,
    },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t("pages.provider_menus.index.title")} />

      <PageContainer
        eyebrow={t("pages.provider_menus.index.eyebrow")}
        title={t("pages.provider_menus.index.title")}
        actions={
          <Button className="ml-auto" asChild>
            <Link href={menusRoutes.new().url}>
              {t("pages.provider_menus.index.add_dish")}
            </Link>
          </Button>
        }
      >
        {/* Listamos los platos y creamos un diálogo para confirmar si eliminarlos. */}
        {menus.length == 0 ? (
          <Empty>
            <EmptyHeader>
              <EmptyTitle>
                {t("pages.provider_menus.index.empty_title")}
              </EmptyTitle>
              <EmptyDescription>
                {t("pages.provider_menus.index.empty_description")}
              </EmptyDescription>
              <EmptyContent>
                <Button asChild>
                  <Link href={menusRoutes.new().url}>
                    {t("pages.provider_menus.index.add_dish")}
                  </Link>
                </Button>
              </EmptyContent>
            </EmptyHeader>
          </Empty>
        ) : (
          <DeleteMenuDialog name={deletingMenu.name} id={deletingMenu.id}>
            <div className="grid grid-cols-2 gap-2">{menusJSX}</div>
          </DeleteMenuDialog>
        )}
      </PageContainer>
    </AppLayout>
  )
}
