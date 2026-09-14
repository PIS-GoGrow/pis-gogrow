import { Link } from "@inertiajs/react"

import { Button } from "@/components/ui/button"
import {
  Card,
  CardAction,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { DialogTrigger } from "@/components/ui/dialog"
import { providerMenus } from "@/routes"
import type { Menu } from "@/types"

export default function MenuCard({
  menu,
  showLink,
  setDeletingMenu,
}: {
  menu: Menu
  showLink: boolean
  setDeletingMenu: React.Dispatch<
    React.SetStateAction<{ id: number | null; name: string }>
  >
}) {
  return (
    <Card key={menu.id} className="w-full">
      <CardHeader>
        <CardTitle>{menu.name}</CardTitle>
        <CardDescription>{menu.description}</CardDescription>
        <CardAction className="ml-auto">
          {showLink && (
            <Button className="mr-2" asChild>
              <Link href={providerMenus.show(menu.id)}> Ver </Link>
            </Button>
          )}
          <DialogTrigger asChild>
            <Button
              variant="outline"
              onClick={() =>
                setDeletingMenu({ id: menu.id, name: String(menu.name) })
              }
            >
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
}
