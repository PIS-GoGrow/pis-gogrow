import { router } from "@inertiajs/react"
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
import {
  Field,
  FieldContent,
  FieldDescription,
  FieldLabel,
  FieldTitle,
} from "@/components/ui/field"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { providerMenus } from "@/routes"
import type { SavedMenu } from "@/types"

type ConfirmedOrders = "keep" | "reject"

const OPTIONS: ConfirmedOrders[] = ["keep", "reject"]

interface DeleteMenuAdaptableDialogProps {
  menu: SavedMenu | null
  onClose: () => void
}

export default function DeleteMenuAdaptableDialog({
  menu,
  onClose,
}: DeleteMenuAdaptableDialogProps) {
  const { t } = useTranslation()
  const key = "pages.schedules.index.saved.delete_sheet"
  const [confirmedOrders, setConfirmedOrders] =
    useState<ConfirmedOrders>("keep")
  const [processing, setProcessing] = useState(false)

  // Solo se pregunta qué hacer con los pedidos si el plato tiene confirmados.
  const hasConfirmed = (menu?.confirmed_orders ?? 0) > 0
  const hasPending = (menu?.pending_orders ?? 0) > 0

  function close() {
    setConfirmedOrders("keep")
    onClose()
  }

  function handleDelete() {
    if (!menu) return

    setProcessing(true)

    router.delete(providerMenus.destroy(menu.id).url, {
      data: { confirmed_orders: confirmedOrders },
      preserveScroll: true,
      onSuccess: close,
      onFinish: () => setProcessing(false),
    })
  }

  return (
    <AdaptableDialog
      open={menu !== null}
      onOpenChange={(open) => !open && close()}
    >
      <AdaptableDialogContent showCloseButton={false} className="p-0">
        <AdaptableDialogHeader className="items-start px-6 pt-8 text-left">
          <AdaptableDialogTitle className="text-base">
            {t(`${key}.title`)}
          </AdaptableDialogTitle>
          <AdaptableDialogDescription className="text-base">
            {hasConfirmed
              ? t(`${key}.description_orders`)
              : t(`${key}.description`)}
            {hasPending && ` ${t(`${key}.pending`)}`}
          </AdaptableDialogDescription>
        </AdaptableDialogHeader>

        {hasConfirmed && (
          <div className="px-6 pt-4">
            <RadioGroup
              value={confirmedOrders}
              onValueChange={(value) =>
                setConfirmedOrders(value as ConfirmedOrders)
              }
              className="gap-3"
            >
              {OPTIONS.map((option) => (
                <FieldLabel key={option} htmlFor={`delete-orders-${option}`}>
                  <Field orientation="horizontal">
                    <RadioGroupItem
                      value={option}
                      id={`delete-orders-${option}`}
                    />
                    <FieldContent>
                      <FieldTitle>
                        {t(`${key}.orders.${option}.title`)}
                      </FieldTitle>
                      <FieldDescription>
                        {t(`${key}.orders.${option}.description`)}
                      </FieldDescription>
                    </FieldContent>
                  </Field>
                </FieldLabel>
              ))}
            </RadioGroup>
          </div>
        )}

        <AdaptableDialogFooter className="flex-row gap-3 px-6 pt-6 pb-6">
          <Button
            type="button"
            variant="secondary"
            className="h-11 flex-1"
            onClick={close}
          >
            {t(`${key}.back`)}
          </Button>
          <Button
            type="button"
            className="h-11 flex-1"
            disabled={processing}
            onClick={handleDelete}
          >
            {processing ? t(`${key}.deleting`) : t(`${key}.confirm`)}
          </Button>
        </AdaptableDialogFooter>
      </AdaptableDialogContent>
    </AdaptableDialog>
  )
}
