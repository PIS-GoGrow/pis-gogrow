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
  CardTitle
} from "@/components/ui/card"
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
      </CardHeader>
      <CardContent>
        <p>{menu.price}$</p>
      </CardContent>
    </Card>
  )

  const [showForm, setShowForm] = useState(false)

  return (
    <div className="m-5 w-250 mx-auto grid gap-2">
	  <div className="flex items-center mb-5">
        <h1 className="text-lg font-bold">Tus platos</h1>
		{ showForm ? (<> </>) : (
		  <Button className="ml-auto" onClick={() => { setShowForm(true); }}>
		  	Agregar plato
		  </Button>
		) }
      </div>
	  { showForm ? (
		<NewForm onCancelar={() => { setShowForm(false); }} />
	  ) : (<></>)}
	  <div className="grid gap-2 grid-cols-2">{menusJSX}</div>
    </div>
  )
}
