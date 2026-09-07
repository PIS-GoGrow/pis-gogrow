import { Link } from '@inertiajs/react'

import { Button } from "@/components/ui/button"
import {
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { menus as menusRoutes } from "@/routes"

export default function DeleteMenuDialog({ name, id, setOpenDelete }: { name: string, id: number, setOpenDelete: React.Dispatch<React.SetStateAction<boolean>> }) {
  return (
    <DialogContent>
      <DialogHeader>
        <DialogTitle>Estás seguro?</DialogTitle>
        <DialogDescription>
          Se borrará el plato &quot;{name}&quot;. Esta acción es irreversible.
        </DialogDescription>
      </DialogHeader>
      <DialogFooter className="sm:justify-start">
        <Button asChild>
          <Link href={menusRoutes.destroy(id)} method="delete" onClick={() => setOpenDelete(false)}>
            Borrar
          </Link>
        </Button>
      </DialogFooter>
    </DialogContent>
  )
}