import { router } from "@inertiajs/react"
import { X } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import {
  AdaptableDialog,
  AdaptableDialogContent,
  AdaptableDialogDescription,
  AdaptableDialogTitle,
  AdaptableDialogTrigger,
} from "@/components/adaptable-dialog"
import { Button } from "@/components/ui/button"
import { Spinner } from "@/components/ui/spinner"
import { consumerOrders } from "@/routes"
import type { Order } from "@/types"

interface CancelOrderSheetProps {
  order: Order
}

export default function CancelOrderSheet({ order }: CancelOrderSheetProps) {
  const { t } = useTranslation()
  const [open, setOpen] = useState(false)
  const [processing, setProcessing] = useState(false)

  function handleCancel() {
    setProcessing(true)

    router.patch(
      consumerOrders.cancel(order.id),
      {},
      {
        preserveScroll: true,
        // Inertia considera exitosa la visita aunque el servidor haya rechazado
        // la cancelación: el flash de error es lo que distingue los dos casos.
        onSuccess: (page) => {
          if (!page.flash.alert) setOpen(false)
        },
        onFinish: () => setProcessing(false),
      },
    )
  }

  return (
    <AdaptableDialog open={open} onOpenChange={setOpen}>
      <AdaptableDialogTrigger asChild>
        <Button
          type="button"
          variant="secondary"
          className="bg-muted hover:bg-muted/80 text-foreground h-10 w-full gap-1.5 rounded-[10px] border-0 text-sm font-medium"
        >
          <X aria-hidden="true" className="size-4" />
          {t("pages.orders.index.cancel")}
        </Button>
      </AdaptableDialogTrigger>

      <AdaptableDialogContent showCloseButton={false} className="p-6">
        <AdaptableDialogTitle className="text-foreground text-base leading-6 font-semibold tracking-normal">
          {t("pages.orders.index.cancel_dialog.title")}
        </AdaptableDialogTitle>
        <AdaptableDialogDescription className="text-muted-foreground mt-2 mb-5 text-base leading-6">
          {t("pages.orders.index.cancel_dialog.description")}
        </AdaptableDialogDescription>

        <div className="grid grid-cols-2 gap-3">
          <Button
            type="button"
            variant="secondary"
            className="bg-muted hover:bg-muted/80 text-foreground h-10 rounded-[10px] border-0 text-base font-medium"
            onClick={() => setOpen(false)}
          >
            {t("pages.orders.index.cancel_dialog.back")}
          </Button>
          <Button
            type="button"
            className="h-10 rounded-[10px] bg-[#171717] text-base font-medium text-[#fafafa] hover:bg-[#171717]/90 dark:bg-zinc-100 dark:text-zinc-900"
            disabled={processing}
            onClick={handleCancel}
          >
            {processing && <Spinner />}
            {t("pages.orders.index.cancel_dialog.confirm")}
          </Button>
        </div>
      </AdaptableDialogContent>
    </AdaptableDialog>
  )
}
