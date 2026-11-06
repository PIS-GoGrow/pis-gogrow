import { router } from "@inertiajs/react"
import { Check, X } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import {
  AdaptableDialog,
  AdaptableDialogClose,
  AdaptableDialogContent,
  AdaptableDialogDescription,
  AdaptableDialogFooter,
  AdaptableDialogHeader,
  AdaptableDialogTitle,
  AdaptableDialogTrigger,
} from "@/components/adaptable-dialog"
import { Button } from "@/components/ui/button"
import {
  Field,
  FieldContent,
  FieldLabel,
  FieldTitle,
} from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { Spinner } from "@/components/ui/spinner"
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

const disabledStyle =
  "disabled:border-transparent disabled:bg-muted disabled:text-muted-foreground disabled:opacity-100 disabled:shadow-none"

// Inertia considera exitosa la visita aunque el servidor haya rechazado la
// decisión: el flash de error es lo que distingue los dos casos.
function alertFrom(page: { props: unknown; flash?: { alert?: string } }) {
  return (
    (page.props as { flash?: { alert?: string } })?.flash?.alert ??
    page.flash?.alert
  )
}

interface ProviderOrderActionsProps {
  order: Pick<ProviderOrder, "id" | "status" | "rejectable" | "consumer_name">
  className?: string
  keepVisible?: boolean
  stackOnMobile?: boolean
}

export default function ProviderOrderActions({
  order,
  className,
  keepVisible = false,
  stackOnMobile = false,
}: ProviderOrderActionsProps) {
  const { t } = useTranslation()
  const [open, setOpen] = useState(false)
  const [processing, setProcessing] = useState(false)
  const [reason, setReason] = useState<OrderRejectionReason | "">("")
  const [details, setDetails] = useState("")
  // Qué decisión se acaba de tomar, para avisar con una hoja de confirmación.
  const [decided, setDecided] = useState<"confirmed" | "rejected" | null>(null)

  const canConfirm = order.status === "pending"
  const canDecideReject = order.rejectable

  if (!canDecideReject && !keepVisible) return null

  const code = t("pages.provider_orders.index.code", { id: order.id })

  function handleConfirm() {
    setProcessing(true)

    router.patch(
      providerOrders.confirm(order.id),
      {},
      {
        preserveScroll: true,
        // Sin preserveState Inertia remonta la página y se pierde el aviso.
        preserveState: true,
        onSuccess: (page) => {
          if (!alertFrom(page)) setDecided("confirmed")
        },
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
        preserveState: true,
        onSuccess: (page) => {
          if (!alertFrom(page)) {
            setOpen(false)
            setReason("")
            setDetails("")
            setDecided("rejected")
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

  // En el detalle el botón de confirmar directamente no va si el pedido ya no
  // se puede confirmar; en las tarjetas de la lista queda, deshabilitado, para
  // que todas las tarjetas tengan la misma altura.
  const showConfirm = canConfirm || !stackOnMobile

  const confirmButton = (
    <Button
      type="button"
      size="lg"
      disabled={processing || !canConfirm}
      className={disabledStyle}
      onClick={handleConfirm}
    >
      <Check aria-hidden="true" />
      {t("pages.provider_orders.actions.confirm")}
    </Button>
  )

  const decidedKey = `pages.provider_orders.actions.${decided ?? "confirmed"}_sheet`

  return (
    <>
      <div
        className={cn(
          "grid gap-2",
          stackOnMobile ? "grid-cols-1 md:grid-cols-2" : "grid-cols-2",
          className,
        )}
      >
        {stackOnMobile && showConfirm && confirmButton}
        <AdaptableDialog open={open} onOpenChange={handleOpenChange}>
          <AdaptableDialogTrigger asChild>
            <Button
              type="button"
              variant="outline"
              size="lg"
              disabled={!canDecideReject}
              className={cn(disabledStyle, stackOnMobile && "md:order-first")}
            >
              <X aria-hidden="true" />
              {t("pages.provider_orders.actions.reject")}
            </Button>
          </AdaptableDialogTrigger>

          <AdaptableDialogContent
            showCloseButton={false}
            className="p-5 md:p-6"
          >
            <AdaptableDialogHeader className="p-0">
              <AdaptableDialogTitle>
                {t("pages.provider_orders.actions.reject_dialog.title")}
              </AdaptableDialogTitle>
              <AdaptableDialogDescription>
                {t("pages.provider_orders.actions.reject_dialog.description")}
              </AdaptableDialogDescription>
            </AdaptableDialogHeader>

            <div className="grid gap-3 py-2">
              <RadioGroup
                value={reason}
                onValueChange={(val) => setReason(val as OrderRejectionReason)}
                className="gap-3"
              >
                {REJECTION_REASONS.map((r) => (
                  <FieldLabel key={r} htmlFor={`reason-${r}`}>
                    <Field orientation="horizontal">
                      <RadioGroupItem value={r} id={`reason-${r}`} />
                      <FieldContent>
                        <FieldTitle>
                          {t(`pages.provider_orders.rejection_reasons.${r}`)}
                        </FieldTitle>
                      </FieldContent>
                    </Field>
                  </FieldLabel>
                ))}
              </RadioGroup>

              {reason === "other" && (
                <Input
                  id="rejection-details"
                  value={details}
                  onChange={(e) => setDetails(e.target.value)}
                  aria-label={t(
                    "pages.provider_orders.actions.reject_dialog.details_label",
                  )}
                  placeholder={t(
                    "pages.provider_orders.actions.reject_dialog.details_placeholder",
                  )}
                />
              )}
            </div>

            <AdaptableDialogFooter className="p-0 max-md:flex-row max-md:gap-3">
              <AdaptableDialogClose asChild>
                <Button
                  type="button"
                  variant="outline"
                  className="max-md:flex-1"
                >
                  {t("pages.provider_orders.actions.reject_dialog.back")}
                </Button>
              </AdaptableDialogClose>
              <Button
                type="button"
                disabled={!canReject}
                className="max-md:flex-1"
                onClick={handleReject}
              >
                {processing && <Spinner />}
                {t("pages.provider_orders.actions.reject_dialog.confirm")}
              </Button>
            </AdaptableDialogFooter>
          </AdaptableDialogContent>
        </AdaptableDialog>

        {!stackOnMobile && confirmButton}
      </div>

      <AdaptableDialog
        open={decided !== null}
        onOpenChange={(next) => !next && setDecided(null)}
      >
        <AdaptableDialogContent showCloseButton={false} className="p-0">
          <AdaptableDialogHeader className="items-start px-6 pt-8 text-left">
            <AdaptableDialogTitle className="text-base">
              {t(`${decidedKey}.title`)}
            </AdaptableDialogTitle>
            <AdaptableDialogDescription className="text-base">
              {t(`${decidedKey}.description`, {
                code,
                name: order.consumer_name,
              })}
            </AdaptableDialogDescription>
          </AdaptableDialogHeader>

          <AdaptableDialogFooter className="px-6 pt-6 pb-6">
            <Button
              type="button"
              className="h-11 w-full"
              onClick={() => setDecided(null)}
            >
              {t(`${decidedKey}.done`)}
            </Button>
          </AdaptableDialogFooter>
        </AdaptableDialogContent>
      </AdaptableDialog>
    </>
  )
}
