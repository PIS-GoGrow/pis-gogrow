import { useTranslation } from "react-i18next"

import { cn } from "@/lib/utils"

import { money } from "./formatters"
import type { DiscountTier } from "./pricing"

interface Props {
  subtotal: number
  total: number
  tiers?: DiscountTier[]
  compact?: boolean
}

export function OrderSummary({
  subtotal,
  total,
  tiers = [],
  compact = false,
}: Props) {
  return (
    <div className={cn("pt-4 text-sm", !compact && "space-y-3")}>
      {!compact && (
        <>
          <div className="flex justify-between">
            <span className="text-muted-foreground">Precio vianda</span>
            <span>{money(subtotal)}</span>
          </div>
          {tiers.map((tier) => (
            <BenefitLine key={tier.percentage} tier={tier} />
          ))}
        </>
      )}
      <div
        className={cn(
          "flex justify-between text-xl font-bold",
          !compact && "border-border border-t pt-3",
        )}
      >
        <span>Monto a pagar</span>
        <span>{money(total)}</span>
      </div>
    </div>
  )
}

export function BenefitLine({
  tier,
  className,
}: {
  tier: DiscountTier
  className?: string
}) {
  const { t } = useTranslation()

  return (
    <div className={cn("flex justify-between", className)}>
      <span className="text-muted-foreground">
        {t("pages.cart.benefit", { percentage: tier.percentage })}
      </span>
      <span className="text-[#29944c]">- {money(tier.discount)}</span>
    </div>
  )
}
