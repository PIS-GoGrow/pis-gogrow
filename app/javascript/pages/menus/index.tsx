import { Head, Link } from '@inertiajs/react'
import type { Menu } from "@/types"
import { menus as menusRoutes } from "@/routes"

interface MenuProps {
  menus: Menu[]
}

export default function Index({ menus }: MenuProps) {
  const menusJSX = menus.map(menu =>
	<div>
	  <p>{menu.name}</p>
		<Link href={menusRoutes.show(menu.id)}> Ver </Link>
	</div>
  )
  return (
    <div>
      <h1>Tus platos</h1>
      <div>{menusJSX}</div>
    </div>
  )
}
