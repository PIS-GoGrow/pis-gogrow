import { useTranslation } from "react-i18next"

import { Spinner } from "@/components/ui/spinner"
import { formatMoney } from "@/lib/money"
import { cn } from "@/lib/utils"

import type { DiscountTier } from "./pricing"

interface Props {
  loading: boolean
  subtotal?: number
  total?: number
  tiers?: DiscountTier[]
  compact?: boolean
}

export function OrderSummary({
  loading,
  subtotal,
  total,
  tiers = [],
  compact = false,
}: Props) {
  const { t } = useTranslation()

  if (!loading) {
    return (
      <div className={cn("pt-4 text-sm", !compact && "space-y-3")}>
        {!compact && (
          <>
            <div className="flex justify-between">
              <span className="text-muted-foreground">
                {t("pages.cart.subtotal")}
              </span>
              <span>{formatMoney(subtotal ?? 0)}</span>
            </div>
            {tiers.length === 0 && <BenefitLine />}
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
          <span>{formatMoney(total ?? 0)}</span>
        </div>
      </div>
    )
  } else {
    return <Spinner className="mx-auto my-4" />
  }
}

// Sin tier, la vianda no tiene ningún subsidio: la línea se muestra igual, en
// $0, para que el desglose diga cuánto cubre GoGrow aunque sea nada.
export function BenefitLine({
  tier,
  className,
}: {
  tier?: DiscountTier
  className?: string
}) {
  const { t } = useTranslation()

  if (!tier) {
    return (
      <div className={cn("flex justify-between", className)}>
        <span className="text-muted-foreground">
          {t("pages.cart.no_benefit")}
        </span>
        <span>{formatMoney(0)}</span>
      </div>
    )
  }

  const label = tier.name
    ? `${tier.name} (${tier.percentage}%)`
    : t("pages.cart.benefit", { percentage: tier.percentage })

  return (
    <div className={cn("flex justify-between", className)}>
      <span className="text-muted-foreground">{label}</span>
      <span className="text-[#29944c]">- {formatMoney(tier.discount)}</span>
    </div>
  )
}
