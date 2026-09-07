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
import type { Menu } from "@/types"

export default function MenuCard({
  menu,
  setDeletingMenu,
}: {
  menu: Menu
  setDeletingMenu: React.Dispatch<React.SetStateAction<boolean>>
}) {
  return (
    <Card key={menu.id} size="sm" className="w-full">
      <CardHeader>
        <CardTitle>{menu.name}</CardTitle>
        <CardDescription>{menu.description}</CardDescription>
        <CardAction>
          <DialogTrigger className="ml-auto">
            <Button
              variant="outline"
              onClick={() => setDeletingMenu({ id: menu.id, name: menu.name })}
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
