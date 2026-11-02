import { router, usePage } from "@inertiajs/react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import {
  AdaptableDialog,
  AdaptableDialogContent,
  AdaptableDialogDescription,
  AdaptableDialogTitle,
} from "@/components/adaptable-dialog"
import { Button } from "@/components/ui/button"
import { consumerOrders } from "@/routes"
import type { FlashData } from "@/types"

export default function OrderUpdatedSheet() {
  const { t } = useTranslation()
  const { flash } = usePage()
  const [open, setOpen] = useState(false)
  const [seenFlash, setSeenFlash] = useState<FlashData>()

  if (flash !== seenFlash) {
    setSeenFlash(flash)
    if (flash.order_updated) setOpen(true)
  }

  function handleOpenChange(next: boolean) {
    setOpen(next)
    if (!next) router.visit(consumerOrders.index().url)
  }

  return (
    <AdaptableDialog open={open} onOpenChange={handleOpenChange}>
      <AdaptableDialogContent showCloseButton={false} className="p-5">
        <AdaptableDialogTitle className="text-base leading-6 font-semibold tracking-normal">
          {t("pages.orders.edit.updated_dialog.title")}
        </AdaptableDialogTitle>
        <AdaptableDialogDescription className="text-base leading-6">
          {t("pages.orders.edit.updated_dialog.description")}
        </AdaptableDialogDescription>

        <Button
          type="button"
          className="h-12 rounded-lg text-base font-medium"
          onClick={() => handleOpenChange(false)}
        >
          {t("pages.orders.edit.updated_dialog.done")}
        </Button>
      </AdaptableDialogContent>
    </AdaptableDialog>
  )
}
