import { router } from "@inertiajs/react"
import { useState } from "react"

import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { menus as menusRoutes } from "@/routes"

export default function DeleteMenuDialog({
  children,
  name,
  id,
}: {
  children: ReactNode
  name: string
  id: number | null
}) {
  const [openDelete, setOpenDelete] = useState(false)
  const [processing, setProcessing] = useState(false)

  function handleDelete() {
    setProcessing(true)

    router.delete(menusRoutes.destroy(Number(id)), {
      onSuccess: () => {
        setOpenDelete(false)
      },
      onFinish: () => {
        setProcessing(false)
      },
    })
  }

  return (
    <Dialog open={openDelete} onOpenChange={setOpenDelete}>
      {children}

      <DialogContent>
        <DialogHeader>
          <DialogTitle>Estás seguro?</DialogTitle>
          <DialogDescription>
            Se borrará el plato &quot;{name}&quot; y toda las planificaciones
            diarias asociadas. Esta acción es irreversible.
          </DialogDescription>
        </DialogHeader>
        <DialogFooter className="sm:justify-start">
          <Button onClick={() => handleDelete()}>
            {processing ? "Borrando..." : "Borrar"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
