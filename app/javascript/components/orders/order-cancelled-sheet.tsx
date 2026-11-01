import { usePage } from "@inertiajs/react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import {
  AdaptableDialog,
  AdaptableDialogContent,
  AdaptableDialogDescription,
  AdaptableDialogTitle,
} from "@/components/adaptable-dialog"
import { Button } from "@/components/ui/button"
import type { FlashData } from "@/types"

export default function OrderCancelledSheet() {
  const { t } = useTranslation()
  const { flash } = usePage()
  const [open, setOpen] = useState(false)
  const [seenFlash, setSeenFlash] = useState<FlashData>()

  if (flash !== seenFlash) {
    setSeenFlash(flash)
    if (flash.order_cancelled) setOpen(true)
  }

  return (
    <AdaptableDialog open={open} onOpenChange={setOpen}>
      <AdaptableDialogContent showCloseButton={false} className="p-5">
        <AdaptableDialogTitle className="text-base leading-6 font-semibold tracking-normal">
          {t("pages.orders.index.cancelled_dialog.title")}
        </AdaptableDialogTitle>
        <AdaptableDialogDescription className="text-base leading-6">
          {t("pages.orders.index.cancelled_dialog.description")}
        </AdaptableDialogDescription>

        <Button
          type="button"
          className="h-12 rounded-lg text-base font-medium"
          onClick={() => setOpen(false)}
        >
          {t("pages.orders.index.cancelled_dialog.done")}
        </Button>
      </AdaptableDialogContent>
    </AdaptableDialog>
  )
}
