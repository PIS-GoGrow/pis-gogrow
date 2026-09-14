import { cn } from "@/lib/utils"

import { money } from "./formatters"

interface Props {
  subtotal: number
  discount: number
  total: number
  percentage: number
  compact?: boolean
}

export function OrderSummary({
  subtotal,
  discount,
  total,
  percentage,
  compact = false,
}: Props) {
  return (
    <div className={cn("pt-4 text-xs", !compact && "space-y-3")}>
      {!compact && (
        <>
          <div className="flex justify-between text-[#777]">
            <span>Precio vianda</span>
            <span>{money(subtotal)}</span>
          </div>
          <div className="flex justify-between text-[#29944c]">
            <span>Beneficio GoGrow ({percentage}%)</span>
            <span>- {money(discount)}</span>
          </div>
        </>
      )}
      <div
        className={cn(
          "flex justify-between text-base font-bold",
          !compact && "border-t border-[#e5e5e5] pt-3",
        )}
      >
        <span>Monto a pagar</span>
        <span>{money(total)}</span>
      </div>
    </div>
  )
}
