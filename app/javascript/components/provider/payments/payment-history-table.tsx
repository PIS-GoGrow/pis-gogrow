import { Eye } from "lucide-react"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"

import type {
  PaymentStatus,
  ProviderPaymentHistoryItem,
} from "./types"

interface Props {
  payments: ProviderPaymentHistoryItem[]
  onSelect: (payment: ProviderPaymentHistoryItem) => void
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

function formatDate(date: string) {
  return new Intl.DateTimeFormat("es-UY").format(
    new Date(`${date}T00:00:00`),
  )
}

export default function PaymentHistoryTable({
  payments,
  onSelect,
}: Props) {
  if (payments.length === 0) {
    return (
      <div className="rounded-xl border border-dashed p-10 text-center text-sm text-muted-foreground">
        No se encontraron pagos para los filtros seleccionados.
      </div>
    )
  }

  return (
    <div className="overflow-x-auto rounded-xl border">
      <div className="min-w-[850px]">
        <div className="grid grid-cols-[1.1fr_1.4fr_1fr_1fr_1fr_1.1fr] items-center gap-4 border-b bg-muted/50 px-4 py-3 text-sm font-medium">
            <span className="text-center">Fecha</span>
            <span>Pagador</span>
            <span className="text-center">Origen</span>
            <span className="text-center">Importe</span>
            <span className="text-center">Estado</span>
            <span />
        </div>

      {payments.map((payment) => (
            <div
            key={payment.id}
            className="grid grid-cols-[1.1fr_1.4fr_1fr_1fr_1fr_1.1fr] items-center gap-4 border-b px-4 py-4 last:border-b-0"
            >
            <span className="justify-self-center text-sm">
            {formatDate(payment.date)}
            </span>

            <span className="font-medium">
            {payment.payer.name}
            </span>

            <span className="justify-self-center text-sm text-muted-foreground">
            {payment.payer.type === "employee"
                ? "Empleado"
                : "GoGrow"}
            </span>

            <span className="justify-self-center font-medium">
            {moneyFormatter.format(payment.amount)}
            </span>

            <Badge
            variant="outline"
            className={`justify-self-center ${statusClasses[payment.status]}`}
            >
            {statusLabels[payment.status]}
            </Badge>

            <Button
            variant="ghost"
            size="sm"
            className="justify-self-center"
            onClick={() => onSelect(payment)}
            >
            <Eye className="mr-2 size-4" />
            Ver detalle
            </Button>
        </div>    
      ))}
    </div>
   </div>

  )
}