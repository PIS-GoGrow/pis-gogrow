import { useTranslation } from "react-i18next"

import {
  AdaptableDialog,
  AdaptableDialogContent,
  AdaptableDialogDescription,
  AdaptableDialogTitle,
} from "@/components/adaptable-dialog"
import { Button } from "@/components/ui/button"
import { Spinner } from "@/components/ui/spinner"

export type ConfirmModifyKind = "modify_confirmed" | "add_units"

interface ConfirmModifyDialogProps {
  kind: ConfirmModifyKind | null
  processing: boolean
  onConfirm: () => void
  onClose: () => void
}

export default function ConfirmModifyDialog({
  kind,
  processing,
  onConfirm,
  onClose,
}: ConfirmModifyDialogProps) {
  const { t } = useTranslation()
  const scope = `pages.orders.edit.${kind ?? "modify_confirmed"}_dialog`

  return (
    <AdaptableDialog
      open={kind !== null}
      onOpenChange={(open) => !open && onClose()}
    >
      <AdaptableDialogContent showCloseButton={false} className="p-5">
        <AdaptableDialogTitle className="text-base leading-6 font-semibold tracking-normal">
          {t(`${scope}.title`)}
        </AdaptableDialogTitle>
        <AdaptableDialogDescription className="text-base leading-6">
          {t(`${scope}.description`)}
        </AdaptableDialogDescription>

        <div className="grid grid-cols-2 gap-3">
          <Button
            type="button"
            variant="outline"
            className="h-12 rounded-lg text-base font-medium"
            disabled={processing}
            onClick={onClose}
          >
            {t(`${scope}.back`)}
          </Button>
          <Button
            type="button"
            className="h-12 rounded-lg text-base font-medium"
            disabled={processing}
            onClick={onConfirm}
          >
            {processing && <Spinner />}
            {t(`${scope}.confirm`)}
          </Button>
        </div>
      </AdaptableDialogContent>
    </AdaptableDialog>
  )
}
