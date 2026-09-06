import { Head, Link } from '@inertiajs/react'
import { useState } from 'react'
import { NewForm } from "./new.tsx"
import type { Menu } from "@/types"
import { menus as menusRoutes } from "@/routes"

import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardAction,
  CardTitle
} from "@/components/ui/card"
import {
  Dialog,
  DialogContent,
  DialogTrigger,
  DialogHeader,
  DialogTitle
} from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"

interface MenuProps {
  menus: Menu[]
}

export default function Index({ menus }: MenuProps) {
  const menusJSX = menus.map(menu =>
	<Card key={menu.id} size="sm" className="w-full ">
      <CardHeader>
		<CardTitle>{menu.name}</CardTitle>
        <CardDescription>
           {menu.description}
        </CardDescription>
		    <CardAction>
          <Button variant="outline">Borrar</Button>
        </CardAction>
      </CardHeader>
      <CardContent>
        <p>{menu.price}$</p>
      </CardContent>
    </Card>
  )

  const [showForm, setShowForm] = useState(false)
  const [open, setOpen] = useState(false)

  return (
    <div className="m-5 w-250 mx-auto grid gap-2">
	  <Dialog open={open} onOpenChange={setOpen}>
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
		  <NewForm onCancelar={() => { setOpen(false); }} />
	    </DialogContent>
      </Dialog>
	  <div className="grid gap-2 grid-cols-2">{menusJSX}</div>
    </div>
  )
}
