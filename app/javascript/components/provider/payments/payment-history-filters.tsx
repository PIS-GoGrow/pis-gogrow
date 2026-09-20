import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"

import type {
  PaymentPayerType,
  PaymentStatus,
} from "./types"

export interface PaymentHistoryFiltersValue {
  from: string
  to: string
  status: PaymentStatus | "all"
  origin: PaymentPayerType | "all"
}

interface Props {
  value: PaymentHistoryFiltersValue
  onChange: (value: PaymentHistoryFiltersValue) => void
}

export default function PaymentHistoryFilters({
  value,
  onChange,
}: Props) {
  function update(
    changes: Partial<PaymentHistoryFiltersValue>,
  ) {
    onChange({
      ...value,
      ...changes,
    })
  }

  function clearFilters() {
    onChange({
      from: "",
      to: "",
      status: "all",
      origin: "all",
    })
  }

  return (
    <div className="flex flex-wrap items-end gap-4 rounded-xl border bg-card p-4">
      <div className="flex flex-col gap-2">
        <label htmlFor="payment-from" className="text-sm font-medium">
          Desde
        </label>

        <Input
          id="payment-from"
          type="date"
          value={value.from}
          onChange={(event) => update({ from: event.target.value })}
        />
      </div>

      <div className="flex flex-col gap-2">
        <label htmlFor="payment-to" className="text-sm font-medium">
          Hasta
        </label>

        <Input
          id="payment-to"
          type="date"
          value={value.to}
          onChange={(event) => update({ to: event.target.value })}
        />
      </div>

      <div className="flex flex-col gap-2">
        <label htmlFor="payment-status" className="text-sm font-medium">
          Estado
        </label>

        <select
          id="payment-status"
          className="h-9 rounded-md border bg-background px-3 text-sm"
          value={value.status}
          onChange={(event) =>
            update({
              status: event.target.value as PaymentHistoryFiltersValue["status"],
            })
          }
        >
          <option value="all">Todos</option>
          <option value="pending">Pendiente</option>
          <option value="submitted">Enviado</option>
          <option value="approved">Aprobado</option>
          <option value="rejected">Rechazado</option>
        </select>
      </div>

      <div className="flex flex-col gap-2">
        <label htmlFor="payment-origin" className="text-sm font-medium">
          Origen
        </label>

        <select
          id="payment-origin"
          className="h-9 rounded-md border bg-background px-3 text-sm"
          value={value.origin}
          onChange={(event) =>
            update({
              origin: event.target.value as PaymentHistoryFiltersValue["origin"],
            })
          }
        >
          <option value="all">Todos</option>
          <option value="employee">Empleado</option>
          <option value="gogrow">GoGrow</option>
        </select>
      </div>

      <Button variant="outline" onClick={clearFilters}>
        Limpiar
      </Button>
    </div>
  )
}