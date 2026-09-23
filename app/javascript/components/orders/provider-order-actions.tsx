import { router } from "@inertiajs/react"
import { Check, X } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import { Spinner } from "@/components/ui/spinner"
import { cn } from "@/lib/utils"
import { providerOrders } from "@/routes"
import type { ProviderOrder } from "@/types"

interface ProviderOrderActionsProps {
  order: Pick<ProviderOrder, "id" | "status">
  className?: string
}

export default function ProviderOrderActions({
  order,
  className,
}: ProviderOrderActionsProps) {
  const { t } = useTranslation()
  const [open, setOpen] = useState(false)
  const [processing, setProcessing] = useState(false)

  if (order.status !== "pending") return null

  const code = t("pages.provider_orders.index.code", { id: order.id })

  function handleConfirm() {
    setProcessing(true)

    router.patch(
      providerOrders.confirm(order.id),
      {},
      {
        preserveScroll: true,
        onFinish: () => setProcessing(false),
      },
    )
  }

  function handleReject() {
    setProcessing(true)

    router.patch(
      providerOrders.reject(order.id),
      {},
      {
        preserveScroll: true,
        // Inertia considera exitosa la visita aunque el servidor haya rechazado
        // la decisión: el flash de error es lo que distingue los dos casos.
        onSuccess: (page) => {
          if (!page.flash.alert) setOpen(false)
        },
        onFinish: () => setProcessing(false),
      },
    )
  }

  return (
    <div className={cn("grid grid-cols-2 gap-2", className)}>
      <Dialog open={open} onOpenChange={setOpen}>
        <DialogTrigger asChild>
          <Button type="button" variant="outline" size="lg">
            <X aria-hidden="true" />
            {t("pages.provider_orders.actions.reject")}
          </Button>
        </DialogTrigger>

        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {t("pages.provider_orders.actions.reject_dialog.title", { code })}
            </DialogTitle>
            <DialogDescription>
              {t("pages.provider_orders.actions.reject_dialog.description")}
            </DialogDescription>
          </DialogHeader>

          <DialogFooter>
            <DialogClose asChild>
              <Button type="button" variant="outline">
                {t("pages.provider_orders.actions.reject_dialog.back")}
              </Button>
            </DialogClose>
            <Button
              type="button"
              variant="destructive"
              disabled={processing}
              onClick={handleReject}
            >
              {processing && <Spinner />}
              {t("pages.provider_orders.actions.reject_dialog.confirm")}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Button
        type="button"
        size="lg"
        disabled={processing}
        onClick={handleConfirm}
      >
        <Check aria-hidden="true" />
        {t("pages.provider_orders.actions.confirm")}
      </Button>
    </div>
  )
}
