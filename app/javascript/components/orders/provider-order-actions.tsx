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
import { Label } from "@/components/ui/label"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { Spinner } from "@/components/ui/spinner"
import { Textarea } from "@/components/ui/textarea"
import { cn } from "@/lib/utils"
import { providerOrders } from "@/routes"
import type { OrderRejectionReason, ProviderOrder } from "@/types"

const REJECTION_REASONS: OrderRejectionReason[] = [
  "out_of_stock",
  "duplicate_order",
  "customer_request",
  "order_error",
  "other",
]

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
  const [reason, setReason] = useState<OrderRejectionReason | "">("")
  const [details, setDetails] = useState("")

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

  const canReject =
    !processing &&
    reason !== "" &&
    (reason !== "other" || details.trim().length > 0)

  function handleReject() {
    if (!canReject) return

    setProcessing(true)

    router.patch(
      providerOrders.reject(order.id),
      {
        reason,
        details: reason === "other" ? details.trim() : null,
      },
      {
        preserveScroll: true,
        // Inertia considera exitosa la visita aunque el servidor haya rechazado
        // la decisión: el flash de error es lo que distingue los dos casos.
        onSuccess: (page) => {
          if (!page.flash.alert) {
            setOpen(false)
            setReason("")
            setDetails("")
          }
        },
        onFinish: () => setProcessing(false),
      },
    )
  }

  function handleOpenChange(nextOpen: boolean) {
    setOpen(nextOpen)
    if (!nextOpen) {
      setReason("")
      setDetails("")
    }
  }

  return (
    <div className={cn("grid grid-cols-2 gap-2", className)}>
      <Dialog open={open} onOpenChange={handleOpenChange}>
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

          <div className="grid gap-4 py-2">
            <RadioGroup
              value={reason}
              onValueChange={(val) => setReason(val as OrderRejectionReason)}
            >
              {REJECTION_REASONS.map((r) => (
                <div key={r} className="flex items-center space-x-2">
                  <RadioGroupItem value={r} id={`reason-${r}`} />
                  <Label htmlFor={`reason-${r}`} className="cursor-pointer">
                    {t(`pages.provider_orders.rejection_reasons.${r}`)}
                  </Label>
                </div>
              ))}
            </RadioGroup>

            {reason === "other" && (
              <div className="grid gap-1.5 pt-1">
                <Label htmlFor="rejection-details">
                  {t(
                    "pages.provider_orders.actions.reject_dialog.details_label",
                  )}
                </Label>
                <Textarea
                  id="rejection-details"
                  value={details}
                  onChange={(e) => setDetails(e.target.value)}
                  placeholder={t(
                    "pages.provider_orders.actions.reject_dialog.details_placeholder",
                  )}
                  rows={3}
                />
              </div>
            )}
          </div>

          <DialogFooter>
            <DialogClose asChild>
              <Button type="button" variant="outline">
                {t("pages.provider_orders.actions.reject_dialog.back")}
              </Button>
            </DialogClose>
            <Button
              type="button"
              variant="destructive"
              disabled={!canReject}
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
