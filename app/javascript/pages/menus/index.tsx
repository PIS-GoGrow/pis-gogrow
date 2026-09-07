import { Link } from '@inertiajs/react'
import { useState } from 'react'

import { Button } from "@/components/ui/button"
import {
  Card,
  CardAction,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle
} from "@/components/ui/card"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger
} from "@/components/ui/dialog"
import { menus as menusRoutes } from "@/routes"
import type { Menu } from "@/types"

import { NewForm } from "./new"

interface MenuProps {
  menus: Menu[]
}

export default function Index({ menus }: MenuProps) {
  const [openCreate, setOpenCreate] = useState(false)
  const [openDelete, setOpenDelete] = useState(false)
  const [deletingMenu, setDeletingMenu] = useState({id: null, name: ''})

  const menusJSX = menus.map((menu: Menu) =>
  	<Card key={menu.id} size="sm" className="w-full">
      <CardHeader>
  		  <CardTitle>{menu.name}</CardTitle>
        <CardDescription>
           {menu.description}
        </CardDescription>
  	    <CardAction>
          <DialogTrigger className="ml-auto">
            <Button variant="outline" onClick={() => setDeletingMenu({id: menu.id, name: menu.name})}>
              Borrar
            </Button>
          </DialogTrigger>
        </CardAction>
      </CardHeader>
      <CardContent>
        <p>{menu.price}$</p>
      </CardContent>
    </Card>
  )

  return (
    <div className="m-5 w-200 mx-auto grid gap-2">
  	  <Dialog open={openCreate} onOpenChange={setOpenCreate}>
  	    <div className="flex items-center mb-5">
          <h1 className="text-xl font-bold">Tus platos</h1>
  		    <DialogTrigger className="ml-auto">
  			    <Button>Agregar plato</Button>
  		    </DialogTrigger>
        </div>
  	    <DialogContent>
  		    <DialogHeader>
            <DialogTitle>Crear plato</DialogTitle>
          </DialogHeader>
  			  <NewForm formSuccess={() => setOpenCreate(false) }/>
  	    </DialogContent>
      </Dialog>

      <Dialog open={openDelete} onOpenChange={setOpenDelete}>
        <div className="grid gap-2 grid-cols-2">{menusJSX}</div>

        <DialogContent>
          <DialogHeader>
            <DialogTitle>Estás seguro?</DialogTitle>
            <DialogDescription>
              Se borrará el plato &quot;{deletingMenu.name}&quot;. Esta acción es irreversible.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter className="sm:justify-start">
            <Button asChild>
              <Link href={menusRoutes.destroy(deletingMenu.id)} method="delete" onClick={() => setOpenDelete(false)}>
                Borrar
              </Link>
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}
