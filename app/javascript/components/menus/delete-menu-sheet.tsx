import { router } from "@inertiajs/react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import { Button } from "@/components/ui/button"
import {
  Field,
  FieldContent,
  FieldDescription,
  FieldLabel,
  FieldTitle,
} from "@/components/ui/field"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetFooter,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet"
import { providerMenus } from "@/routes"
import type { SavedMenu } from "@/types"

type ConfirmedOrders = "keep" | "reject"

const OPTIONS: ConfirmedOrders[] = ["keep", "reject"]

interface DeleteMenuSheetProps {
  menu: SavedMenu | null
  onClose: () => void
}

export default function DeleteMenuSheet({
  menu,
  onClose,
}: DeleteMenuSheetProps) {
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
    <Sheet open={menu !== null} onOpenChange={(open) => !open && close()}>
      <SheetContent
        side="bottom"
        showCloseButton={false}
        className="mx-auto gap-0 rounded-t-3xl pb-[env(safe-area-inset-bottom)] md:max-w-xl"
      >
        <div className="bg-muted-foreground/30 mx-auto mt-3 h-1 w-10 rounded-full" />

        <SheetHeader className="items-start px-6 pt-8 text-left">
          <SheetTitle className="text-base">{t(`${key}.title`)}</SheetTitle>
          <SheetDescription className="text-base">
            {hasConfirmed
              ? t(`${key}.description_orders`)
              : t(`${key}.description`)}
            {hasPending && ` ${t(`${key}.pending`)}`}
          </SheetDescription>
        </SheetHeader>

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

        <SheetFooter className="flex-row gap-3 px-6 pt-6 pb-6">
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
        </SheetFooter>
      </SheetContent>
    </Sheet>
  )
}
