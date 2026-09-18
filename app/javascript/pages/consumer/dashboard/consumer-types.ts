import type { ConsumerDashboardIndex } from "@/types"

export type Schedule = ConsumerDashboardIndex["schedules"][number]
export type CartItem = Schedule & {
  cartId: string
  quantity: number
  notes: string
}
