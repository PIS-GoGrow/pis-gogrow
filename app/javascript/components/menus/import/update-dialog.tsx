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
import type { ConfirmedOrders } from "@/lib/menu-import"

interface UpdateDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onApply: (confirmedOrders: ConfirmedOrders) => void
}

// Avisa antes de pisar un plato guardado y, si tiene pedidos ya confirmados,
// pregunta qué hacer con ellos. Cuando no los tiene no se muestra: la pantalla
// aplica "Actualizar" derecho.
export default function UpdateDialog({
  open,
  onOpenChange,
  onApply,
}: UpdateDialogProps) {
  const { t } = useTranslation()
  const key = "pages.provider_menu_imports.new.update_dialog"
  const [confirmedOrders, setConfirmedOrders] =
    useState<ConfirmedOrders>("keep")

  return (
    <AdaptableDialog open={open} onOpenChange={onOpenChange}>
      <AdaptableDialogContent showCloseButton={false} className="p-0">
        <AdaptableDialogHeader className="items-start px-6 pt-8 text-left">
          <AdaptableDialogTitle className="text-base">
            {t(`${key}.title`)}
          </AdaptableDialogTitle>
          <AdaptableDialogDescription>
            {t(`${key}.description`)}
          </AdaptableDialogDescription>
        </AdaptableDialogHeader>

        <RadioGroup
          value={confirmedOrders}
          onValueChange={(value) =>
            setConfirmedOrders(value as ConfirmedOrders)
          }
          className="gap-3 px-6 pt-2"
        >
          {(["keep", "reject"] as const).map((option) => (
            <FieldLabel key={option} htmlFor={`confirmed-orders-${option}`}>
              <Field orientation="horizontal">
                <RadioGroupItem
                  value={option}
                  id={`confirmed-orders-${option}`}
                />
                <FieldContent>
                  <FieldTitle>{t(`${key}.${option}`)}</FieldTitle>
                  <FieldDescription>
                    {t(`${key}.${option}_description`)}
                  </FieldDescription>
                </FieldContent>
              </Field>
            </FieldLabel>
          ))}
        </RadioGroup>

        <AdaptableDialogFooter className="grid grid-cols-2 gap-3 px-6 pt-6 pb-6">
          <Button
            type="button"
            variant="secondary"
            className="h-11"
            onClick={() => onOpenChange(false)}
          >
            {t(`${key}.back`)}
          </Button>

          <Button
            type="button"
            className="h-11"
            onClick={() => onApply(confirmedOrders)}
          >
            {t(`${key}.apply`)}
          </Button>
        </AdaptableDialogFooter>
      </AdaptableDialogContent>
    </AdaptableDialog>
  )
}
