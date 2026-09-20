import { ExternalLink } from "lucide-react"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"

import type {
  PaymentStatus,
  ProviderPaymentHistoryItem,
} from "./types"

interface Props {
  payment: ProviderPaymentHistoryItem | null
  open: boolean
  onOpenChange: (open: boolean) => void
}

const statusLabels: Record<PaymentStatus, string> = {
  pending: "Pendiente",
  submitted: "Enviado",
  approved: "Aprobado",
  rejected: "Rechazado",
}

const statusClasses: Record<PaymentStatus, string> = {
  pending:
    "border-amber-300 bg-amber-100 text-amber-800 dark:border-amber-900 dark:bg-amber-950 dark:text-amber-300",
  submitted:
    "border-blue-300 bg-blue-100 text-blue-800 dark:border-blue-900 dark:bg-blue-950 dark:text-blue-300",
  approved:
    "border-emerald-300 bg-emerald-100 text-emerald-800 dark:border-emerald-900 dark:bg-emerald-950 dark:text-emerald-300",
  rejected:
    "border-red-300 bg-red-100 text-red-800 dark:border-red-900 dark:bg-red-950 dark:text-red-300",
}

const moneyFormatter = new Intl.NumberFormat("es-UY", {
  style: "currency",
  currency: "UYU",
})

function formatDateTime(value: string) {
  return new Intl.DateTimeFormat("es-UY", {
    dateStyle: "short",
    timeStyle: "short",
  }).format(new Date(value))
}

export default function PaymentHistoryDetail({
  payment,
  open,
  onOpenChange,
}: Props) {
  if (!payment) return null

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl">
        <DialogHeader>
          <DialogTitle>Detalles del pago</DialogTitle>

        </DialogHeader>

        <div className="flex flex-col gap-6">
          <div className="grid gap-4 sm:grid-cols-2">
            <div>
              <p className="text-xs text-muted-foreground">
                Pagador
              </p>
              <p className="font-medium">
                {payment.payer.name}
              </p>
            </div>

            <div>
              <p className="text-xs text-muted-foreground">
                Origen
              </p>
              <p className="font-medium">
                {payment.payer.type === "employee"
                  ? "Empleado"
                  : "GoGrow"}
              </p>
            </div>

            <div>
              <p className="text-xs text-muted-foreground">
                Importe
              </p>
              <p className="font-medium">
                {moneyFormatter.format(payment.amount)}
              </p>
            </div>

            <div>
              <p className="text-xs text-muted-foreground">
                Estado actual
              </p>

              <Badge
                variant="outline"
                className={statusClasses[payment.status]}
                >
                {statusLabels[payment.status]}
              </Badge>
            </div>
          </div>

          <div className="flex flex-col gap-2">
            <h3 className="font-semibold">
              Conceptos asociados
            </h3>

            <div className="rounded-lg border">
              {payment.concepts.map((concept) => (
                <div
                  key={concept.id}
                  className="flex items-center justify-between border-b px-4 py-3 last:border-b-0"
                >
                  <span className="text-sm">
                    {concept.description}
                  </span>

                  <span className="font-medium">
                    {moneyFormatter.format(concept.amount)}
                  </span>
                </div>
              ))}
            </div>
          </div>

          <div className="flex flex-col gap-2">
            <h3 className="font-semibold">
              Comprobante
            </h3>

            {payment.receiptUrl ? (
              <Button variant="outline" asChild>
                <a
                  href={payment.receiptUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  <ExternalLink className="mr-2 size-4" />
                  Ver comprobante
                </a>
              </Button>
            ) : (
              <p className="text-sm text-muted-foreground">
                No hay comprobante disponible.
              </p>
            )}
          </div>

          <div className="flex flex-col gap-2">
            <h3 className="font-semibold">
              Historial de estados
            </h3>

            <div className="flex flex-col gap-3 rounded-lg border p-4">
              {payment.statusHistory.map((entry, index) => (
                <div
                  key={`${entry.status}-${entry.changedAt}-${index}`}
                  className="flex items-center justify-between gap-4"
                >
                  <Badge
                    variant="outline"
                    className={statusClasses[entry.status]}
                    >
                    {statusLabels[entry.status]}
                  </Badge>

                  <span className="text-sm text-muted-foreground">
                    {formatDateTime(entry.changedAt)}
                  </span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}