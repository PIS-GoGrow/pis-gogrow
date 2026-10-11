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
  const { t } = useTranslation()

  return (
    <div className={cn("pt-4 text-sm", !compact && "space-y-3")}>
      {!compact && (
        <>
          <div className="flex justify-between">
            <span className="text-muted-foreground">
              {t("pages.cart.subtotal")}
            </span>
            <span>{money(subtotal)}</span>
          </div>
          {tiers.map((tier, index) => (
            <BenefitLine
              key={`${tier.name ?? "base"}-${tier.percentage}-${index}`}
              tier={tier}
            />
          ))}
        </>
      )}
      <div
        className={cn(
          "flex justify-between text-xl font-bold",
          !compact && "border-border border-t pt-3",
        )}
      >
        <span>{t("pages.cart.total")}</span>
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

  const label = tier.name
    ? `${tier.name} (${tier.percentage}%)`
    : t("pages.cart.benefit", { percentage: tier.percentage })

  return (
    <div className={cn("flex justify-between", className)}>
      <span className="text-muted-foreground">{label}</span>
      <span className="text-green-700 dark:text-green-500 font-normal">
        - {money(tier.discount)}
      </span>
    </div>
  )
}
