export type PaymentStatus =
  | "pending"
  | "submitted"
  | "approved"
  | "rejected"

export type PaymentPayerType = "employee" | "gogrow"

export interface PaymentConcept {
  id: number
  description: string
  amount: number
}

export interface PaymentStatusChange {
  status: PaymentStatus
  changedAt: string
}

export interface ProviderPaymentHistoryItem {
  id: number
  date: string
  amount: number

  payer: {
    type: PaymentPayerType
    name: string
  }

  status: PaymentStatus
  receiptUrl: string | null
  concepts: PaymentConcept[]
  statusHistory: PaymentStatusChange[]
}