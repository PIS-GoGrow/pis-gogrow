import { router } from "@inertiajs/react"
import type { ReactNode } from "react"
import { useState } from "react"

import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { Field, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { cn } from "@/lib/utils"
import { providerPayments as paymentsRoutes } from "@/routes"

const REJECTION_REASONS = [
  "La imagen está borrosa",
  "El archivo enviado no corresponde a un comprobante",
  "Los montos de deuda y pago no coinciden",
]

const OTHER_OPTION = "other"

interface RejectPaymentDialogProps {
  children: ReactNode
  paymentId: number
}

export default function RejectPaymentDialog({
  children,
  paymentId,
}: RejectPaymentDialogProps) {
  const [open, setOpen] = useState(false)
  const [selectedReason, setSelectedReason] = useState<string>(
    REJECTION_REASONS[0],
  )
  const [customReason, setCustomReason] = useState("")
  const [processing, setProcessing] = useState(false)

  const isOther = selectedReason === OTHER_OPTION
  const finalReason = isOther ? customReason.trim() : selectedReason
  const canSubmit = finalReason.length > 0

  function resetForm() {
    setSelectedReason(REJECTION_REASONS[0])
    setCustomReason("")
  }

  function handleReject() {
    if (!canSubmit) return

    setProcessing(true)

    router.patch(
      paymentsRoutes.update(paymentId).url,
      { status: "rejected", rejection_reason: finalReason },
      {
        onSuccess: () => {
          setOpen(false)
          resetForm()
        },
        onFinish: () => setProcessing(false),
      },
    )
  }

  return (
    <Dialog
      open={open}
      onOpenChange={(nextOpen) => {
        setOpen(nextOpen)
        if (!nextOpen) resetForm()
      }}
    >
      {children}

      <DialogContent>
        <DialogHeader>
          <DialogTitle>Rechazar comprobante</DialogTitle>
          <DialogDescription>
            Elegí el motivo del rechazo. El empleado va a ver este mensaje.
          </DialogDescription>
        </DialogHeader>

        <div className="flex flex-col gap-2">
          {REJECTION_REASONS.map((reason) => (
            <label
              key={reason}
              className={cn(
                "flex cursor-pointer items-center gap-3 rounded-xl border p-3 text-sm transition-colors",
                selectedReason === reason
                  ? "border-primary bg-primary/5"
                  : "hover:border-primary/50",
              )}
            >
              <input
                type="radio"
                name="rejection_reason"
                className="accent-primary"
                checked={selectedReason === reason}
                onChange={() => setSelectedReason(reason)}
              />
              {reason}
            </label>
          ))}

          <label
            className={cn(
              "flex cursor-pointer items-center gap-3 rounded-xl border p-3 text-sm transition-colors",
              isOther ? "border-primary bg-primary/5" : "hover:border-primary/50",
            )}
          >
            <input
              type="radio"
              name="rejection_reason"
              className="accent-primary"
              checked={isOther}
              onChange={() => setSelectedReason(OTHER_OPTION)}
            />
            Otro
          </label>

          {isOther && (
            <Field className="pl-9">
              <FieldLabel htmlFor="custom-reason" className="sr-only">
                Motivo
              </FieldLabel>
              <Input
                id="custom-reason"
                placeholder="Escribí el motivo..."
                value={customReason}
                onChange={(e) => setCustomReason(e.target.value)}
              />
            </Field>
          )}
        </div>

        <DialogFooter className="sm:justify-start">
          <Button
            className="flex-1 bg-black text-white hover:bg-black/90" 
            size="sm"
            onClick={handleReject}
          >
            {processing ? "Rechazando..." : "Rechazar comprobante"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
