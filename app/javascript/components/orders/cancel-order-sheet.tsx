import { router } from "@inertiajs/react"
import { X } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import { Button } from "@/components/ui/button"
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet"
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
    <Sheet open={open} onOpenChange={setOpen}>
      <SheetTrigger asChild>
        <Button type="button" variant="outline" size="sm" className="w-full">
          <X aria-hidden="true" />
          {t("pages.orders.index.cancel")}
        </Button>
      </SheetTrigger>

      <SheetContent
        side="bottom"
        showCloseButton={false}
        className="border-border bg-background text-foreground gap-6 rounded-t-[32px] border px-6 pt-2.5 pb-8 shadow-none md:inset-x-1/2 md:bottom-1/2 md:w-[402px] md:translate-x-[-50%] md:translate-y-1/2 md:rounded-[32px]"
      >
        <div
          aria-hidden="true"
          className="bg-muted-foreground/30 mx-auto h-1 w-12 rounded-full"
        />

        <div className="flex flex-col gap-5">
          <SheetTitle className="text-base leading-6 font-semibold tracking-normal">
            {t("pages.orders.index.cancel_dialog.title")}
          </SheetTitle>
          <SheetDescription className="text-base leading-6">
            {t("pages.orders.index.cancel_dialog.description")}
          </SheetDescription>

          <div className="grid grid-cols-2 gap-3">
            <Button
              type="button"
              variant="outline"
              className="h-12 rounded-lg text-base font-medium"
              onClick={() => setOpen(false)}
            >
              {t("pages.orders.index.cancel_dialog.back")}
            </Button>
            <Button
              type="button"
              className="h-12 rounded-lg text-base font-medium"
              disabled={processing}
              onClick={handleCancel}
            >
              {processing && <Spinner />}
              {t("pages.orders.index.cancel_dialog.confirm")}
            </Button>
          </div>
        </div>
      </SheetContent>
    </Sheet>
  )
}
