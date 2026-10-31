import { CircleX, TriangleAlert } from "lucide-react"

import { PARTIAL_PAYMENT_REJECTION_REASON } from "@/lib/payment-rejection-reasons"

interface RejectionNoticeProps {
  reason: string
  partialPaymentWarning: string
  rejectedLabel: string
}

export default function RejectionNotice({
  reason,
  partialPaymentWarning,
  rejectedLabel,
}: RejectionNoticeProps) {
  if (reason === PARTIAL_PAYMENT_REJECTION_REASON) {
    return (
      <div className="flex items-start gap-2 text-sm text-amber-700 dark:text-amber-400">
        <TriangleAlert className="mt-0.5 size-4 shrink-0" />
        <p>{partialPaymentWarning}</p>
      </div>
    )
  }

  return (
    <div className="flex items-start gap-2 rounded-md bg-red-50 p-3 text-sm text-red-700 dark:bg-red-950 dark:text-red-400">
      <CircleX className="mt-0.5 size-4 shrink-0" />
      <p>
        <span className="font-medium">{rejectedLabel}:</span> {reason}
      </p>
    </div>
  )
}
