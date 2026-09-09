import type { ReactNode } from "react";
import { useState } from "react"

import NewMenuForm from "@/components/menus/new-menu-form"
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"

interface CreateMenuProps {
  children: ReactNode
}

export default function CreateMenuDialog({ children }: CreateMenuProps) {
  const [openCreate, setOpenCreate] = useState(false)

  return (
    <Dialog open={openCreate} onOpenChange={setOpenCreate}>
      {children}

      <DialogContent>
        <DialogHeader>
          <DialogTitle>Crear plato</DialogTitle>
        </DialogHeader>
        <NewMenuForm formSuccess={() => setOpenCreate(false)} />
      </DialogContent>
    </Dialog>
  )
}
