import { useMemo, useState } from "react"

import PaymentHistoryDetail from "./payment-history-detail"
import PaymentHistoryFilters, {
  type PaymentHistoryFiltersValue,
} from "./payment-history-filters"
import PaymentHistoryTable from "./payment-history-table"
import type { ProviderPaymentHistoryItem } from "./types"

interface Props {
  payments: ProviderPaymentHistoryItem[]
}

const initialFilters: PaymentHistoryFiltersValue = {
  from: "",
  to: "",
  status: "all",
  origin: "all",
}

export default function PaymentHistoryView({ payments }: Props) {
  const [filters, setFilters] =
    useState<PaymentHistoryFiltersValue>(initialFilters)

  const [selectedPayment, setSelectedPayment] =
    useState<ProviderPaymentHistoryItem | null>(null)

  const filteredPayments = useMemo(() => {
    return payments.filter((payment) => {
      if (filters.from && payment.date < filters.from) {
        return false
      }

      if (filters.to && payment.date > filters.to) {
        return false
      }

      if (
        filters.status !== "all" &&
        payment.status !== filters.status
      ) {
        return false
      }

      if (
        filters.origin !== "all" &&
        payment.payer.type !== filters.origin
      ) {
        return false
      }

      return true
      
    })
  }, [payments, filters])

  return (
    <div className="flex flex-col gap-6">
      <PaymentHistoryFilters
        value={filters}
        onChange={setFilters}
      />

      <PaymentHistoryTable
        payments={filteredPayments}
        onSelect={setSelectedPayment}
      />

      <PaymentHistoryDetail
        payment={selectedPayment}
        open={selectedPayment !== null}
        onOpenChange={(open) => {
          if (!open) {
            setSelectedPayment(null)
          }
        }}
      />
    </div>
  )
}