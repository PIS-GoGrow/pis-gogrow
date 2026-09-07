import { router } from "@inertiajs/react"
import { useState } from "react"

import { Button } from "@/components/ui/button"
import {
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { menus as menusRoutes } from "@/routes"

export default function DeleteMenuDialog({
  name,
  id,
  setOpenDelete,
}: {
  name: string
  id: number | null
  setOpenDelete: React.Dispatch<React.SetStateAction<boolean>>
}) {
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

  if (id == null) return <></>

  return (
    <DialogContent>
      <DialogHeader>
        <DialogTitle>Estás seguro?</DialogTitle>
        <DialogDescription>
          Se borrará el plato &quot;{name}&quot;. Esta acción es irreversible.
        </DialogDescription>
      </DialogHeader>
      <DialogFooter className="sm:justify-start">
        <Button onClick={() => handleDelete()}>
          {processing ? "Borrando..." : "Borrar"}
        </Button>
      </DialogFooter>
    </DialogContent>
  )
}
