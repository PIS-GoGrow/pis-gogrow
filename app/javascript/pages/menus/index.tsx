import { useState } from "react"

import CreateMenuDialog from "@/components/create-menu-dialog"
import DeleteMenuDialog from "@/components/delete-menu-dialog"
import MenuCard from "@/components/menu-card"
import { Button } from "@/components/ui/button"
import { Dialog, DialogTrigger } from "@/components/ui/dialog"
import type { Menu } from "@/types"

interface MenuProps {
  menus: Menu[]
}

export default function Index({ menus }: MenuProps) {
  const [openCreate, setOpenCreate] = useState(false)
  const [openDelete, setOpenDelete] = useState(false)
  const [deletingMenu, setDeletingMenu] = useState<{
    id: number | null
    name: string
  }>({ id: null, name: "" })

  const menusJSX = menus.map((menu: Menu) => (
    <MenuCard key={menu.id} menu={menu} setDeletingMenu={setDeletingMenu} />
  ))

  return (
    <div className="m-5 mx-auto grid w-200 gap-2">
      {/* Agregamos un diálogo al lado del título para mostrar el formulario de crear platos */}
      <Dialog open={openCreate} onOpenChange={setOpenCreate}>
        <div className="mb-5 flex items-center">
          <h1 className="text-xl font-bold">Tus platos</h1>
          <DialogTrigger className="ml-auto">
            <Button>Agregar plato</Button>
          </DialogTrigger>
        </div>
        <CreateMenuDialog setOpenCreate={setOpenCreate} />
      </Dialog>

      {/* Listamos los platos y creamos un diálogo para confirmar si eliminarlos. */}
      <Dialog open={openDelete} onOpenChange={setOpenDelete}>
        <div className="grid grid-cols-2 gap-2">{menusJSX}</div>

        <DeleteMenuDialog
          name={deletingMenu.name}
          id={deletingMenu.id}
          setOpenDelete={setOpenDelete}
        />
      </Dialog>
    </div>
  )
}
