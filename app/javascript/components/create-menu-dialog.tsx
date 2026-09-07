import NewMenuForm from "@/components/new-menu-form"
import {
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"

export default function CreateMenuDialog({ setOpenCreate }: { setOpenCreate: React.Dispatch<React.SetStateAction<boolean>> }) {
  return (
    <DialogContent>
      <DialogHeader>
        <DialogTitle>Crear plato</DialogTitle>
      </DialogHeader>
      <NewMenuForm formSuccess={() => setOpenCreate(false) }/>
    </DialogContent>
  )
}