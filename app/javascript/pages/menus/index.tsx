import { Head } from '@inertiajs/react'
import type { Menu } from "@/types"

interface MenuProps {
  menus: Menu[]
}

export default function Index({ menus }: MenuProps) {
  const menusJSX = menus.map(menu =>
	<div>
	  <p>{menu.name}</p>
	</div>
  )
  return (
    <div>
      <Head title="Welcome" />
      <h1>Welcome</h1>
      <div>{menusJSX}</div>
    </div>
  )
}
