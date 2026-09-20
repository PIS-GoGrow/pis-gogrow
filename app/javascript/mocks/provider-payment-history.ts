import type { ProviderPaymentHistoryItem } from "@/components/provider/payments/types"

export const providerPaymentHistoryMock: ProviderPaymentHistoryItem[] = [
  {
    id: 1,
    date: "2026-09-18",
    amount: 850,
    payer: {
      type: "employee",
      name: "Juan Pérez",
    },
    status: "submitted",
    receiptUrl: null,
    concepts: [
      {
        id: 1,
        description: "Vianda - 18/09/2026",
        amount: 850,
      },
    ],
    statusHistory: [
      {
        status: "pending",
        changedAt: "2026-09-18T12:30:00",
      },
      {
        status: "submitted",
        changedAt: "2026-09-18T14:10:00",
      },
    ],
  },
  {
    id: 2,
    date: "2026-09-17",
    amount: 920,
    payer: {
      type: "employee",
      name: "María Rodríguez",
    },
    status: "approved",
    receiptUrl: null,
    concepts: [
      {
        id: 2,
        description: "Vianda - 17/09/2026",
        amount: 920,
      },
    ],
    statusHistory: [
      {
        status: "pending",
        changedAt: "2026-09-17T12:00:00",
      },
      {
        status: "submitted",
        changedAt: "2026-09-17T15:25:00",
      },
      {
        status: "approved",
        changedAt: "2026-09-18T09:15:00",
      },
    ],
  },
  {
    id: 3,
    date: "2026-09-15",
    amount: 12400,
    payer: {
      type: "gogrow",
      name: "GoGrow",
    },
    status: "approved",
    receiptUrl: null,
    concepts: [
      {
        id: 3,
        description: "Subsidios del período",
        amount: 12400,
      },
    ],
    statusHistory: [
      {
        status: "pending",
        changedAt: "2026-09-15T09:00:00",
      },
      {
        status: "approved",
        changedAt: "2026-09-16T11:30:00",
      },
    ],
  },
  {
    id: 4,
    date: "2026-09-12",
    amount: 780,
    payer: {
      type: "employee",
      name: "Lucía Fernández",
    },
    status: "rejected",
    receiptUrl: null,
    concepts: [
      {
        id: 4,
        description: "Vianda - 12/09/2026",
        amount: 780,
      },
    ],
    statusHistory: [
      {
        status: "pending",
        changedAt: "2026-09-12T13:00:00",
      },
      {
        status: "submitted",
        changedAt: "2026-09-12T14:00:00",
      },
      {
        status: "rejected",
        changedAt: "2026-09-13T10:20:00",
      },
    ],
  },
]