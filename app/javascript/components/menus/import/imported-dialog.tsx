import { Link } from "@inertiajs/react"
import { useTranslation } from "react-i18next"

import {
  AdaptableDialog,
  AdaptableDialogContent,
  AdaptableDialogDescription,
  AdaptableDialogFooter,
  AdaptableDialogHeader,
  AdaptableDialogTitle,
} from "@/components/adaptable-dialog"
import { Button } from "@/components/ui/button"
import { schedules } from "@/routes"

interface ImportedDialogProps {
  open: boolean
  onAgain: () => void
}

// No se cierra solo: importar es el final del flujo, así que el proveedor elige
// si vuelve al menú a ver sus platos o sigue con otra planilla.
export default function ImportedDialog({ open, onAgain }: ImportedDialogProps) {
  const { t } = useTranslation()
  const key = "pages.provider_menu_imports.new.imported"

  return (
    <AdaptableDialog open={open}>
      <AdaptableDialogContent showCloseButton={false} className="p-0">
        <AdaptableDialogHeader className="items-start px-6 pt-8 text-left">
          <AdaptableDialogTitle className="text-base">
            {t(`${key}.title`)}
          </AdaptableDialogTitle>
          <AdaptableDialogDescription>
            {t(`${key}.description`)}
          </AdaptableDialogDescription>
        </AdaptableDialogHeader>

        <AdaptableDialogFooter className="grid grid-cols-2 gap-3 px-6 pt-6 pb-6">
          <Button type="button" variant="secondary" className="h-11" asChild>
            <Link href={schedules.index({ query: { tab: "saved" } }).url}>
              {t(`${key}.back`)}
            </Link>
          </Button>

          <Button type="button" className="h-11" onClick={onAgain}>
            {t(`${key}.again`)}
          </Button>
        </AdaptableDialogFooter>
      </AdaptableDialogContent>
    </AdaptableDialog>
  )
}
