import type { ConsumerDashboardIndex } from "@/types"

export type Schedule = ConsumerDashboardIndex["schedules"][number]
export type CartItem = Schedule & { quantity: number; notes: string }
