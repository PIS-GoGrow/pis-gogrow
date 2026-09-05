import { Head, Link } from '@inertiajs/react'
import type { Menu } from "@/types"
import { menus as menusRoutes } from "@/routes"

interface MenuProps {
  menus: Menu[]
}

export default function Index({ menus }: MenuProps) {
  const menusJSX = menus.map(menu =>
	<div key={menu.id}>
	  <p>{menu.name}</p>
		<Link href={menusRoutes.show(menu.id)}> Ver </Link>
	</div>
  )
  return (
    <div>
      <h1>Tus platos</h1>
	  <Link href={menusRoutes.new()}> Agegar plato </Link>
      <div>{menusJSX}</div>
    </div>
  )
}
