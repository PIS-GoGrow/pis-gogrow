import { Link } from '@inertiajs/react'

import { menus as menusRoutes } from "@/routes"
import type { Menu } from "@/types"

interface MenuProps {
  menu: Menu
}

export default function Show({ menu }: MenuProps) {
  return (
    <div>
      <h1>{menu.name}</h1>
	  <p>Descripción: {menu.description}</p>
	  <p>Precio: {menu.price}</p>
	  <Link href={menusRoutes.index()}> Atrás </Link>
    </div>
  )
}
