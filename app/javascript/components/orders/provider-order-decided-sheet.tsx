import { useState } from "react"
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
import type { ProviderOrder } from "@/types"

export interface ProviderOrderDecision {
  id: ProviderOrder["id"]
  consumer_name: ProviderOrder["consumer_name"]
  status: "confirmed" | "rejected"
}

interface ProviderOrderDecidedSheetProps {
  decision: ProviderOrderDecision | null
  onClose: () => void
}

// Vive en la página y no en la tarjeta: al decidir, el pedido puede salir de la
// lista filtrada y su tarjeta se desmonta.
export default function ProviderOrderDecidedSheet({
  decision,
  onClose,
}: ProviderOrderDecidedSheetProps) {
  const { t } = useTranslation()
  // Conserva el texto mientras la hoja se cierra con su animación.
  const [shown, setShown] = useState(decision)

  if (decision && decision !== shown) setShown(decision)
  if (!shown) return null

  const key = `pages.provider_orders.actions.${shown.status}_sheet`

  return (
    <AdaptableDialog open={decision !== null}>
      <AdaptableDialogContent showCloseButton={false} className="p-0">
        <AdaptableDialogHeader className="items-start px-6 pt-8 text-left">
          <AdaptableDialogTitle className="text-base">
            {t(`${key}.title`)}
          </AdaptableDialogTitle>
          <AdaptableDialogDescription className="text-base">
            {t(`${key}.description`, {
              code: t("pages.provider_orders.index.number", { id: shown.id }),
              name: shown.consumer_name,
            })}
          </AdaptableDialogDescription>
        </AdaptableDialogHeader>

        <AdaptableDialogFooter className="px-6 pt-6 pb-6">
          <Button type="button" className="h-11 w-full" onClick={onClose}>
            {t(`${key}.done`)}
          </Button>
        </AdaptableDialogFooter>
      </AdaptableDialogContent>
    </AdaptableDialog>
  )
}
