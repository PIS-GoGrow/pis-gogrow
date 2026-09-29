import type { ConsumerDashboardIndex } from "@/types"

export type Schedule = ConsumerDashboardIndex["schedules"][number]
export type OptionGroup = Schedule["menu"]["option_groups"][number]
// Lo elegido por grupo, indexado por id del grupo.
export type Selections = Record<number, string[]>
export type CartItem = Schedule & {
  cartId: string
  quantity: number
  notes: string
  selections: Selections
}
export type DeliveryAddressOption = ConsumerDashboardIndex["addresses"][number]
