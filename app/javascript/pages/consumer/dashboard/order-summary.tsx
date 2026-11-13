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
  specialBenefitIds?: number[]
  compact?: boolean
  showTotal?: boolean
  className?: string
}

export function OrderSummary({
  loading,
  subtotal,
  total,
  tiers = [],
  specialBenefitIds = [],
  compact = false,
  showTotal = true,
  className,
}: Props) {
  const { t } = useTranslation()

  if (!loading) {
    return (
      <div className={cn("pt-4 text-sm", !compact && "space-y-3", className)}>
        {!compact && (
          <>
            <div className="flex justify-between">
              <span className="text-muted-foreground text-sm">
                {t("pages.cart.subtotal")}
              </span>
              <span className="text-sm font-normal text-[#171717] dark:text-neutral-100">{formatMoney(subtotal ?? 0)}</span>
            </div>
            {tiers.length === 0 && <BenefitLine />}
            {tiers.map((tier, index) => (
              <BenefitLine
                key={`${tier.name ?? "base"}-${tier.percentage}-${index}`}
                tier={tier}
                special={specialBenefitIds.includes(tier.id)}
              />
            ))}
          </>
        )}
        {showTotal && (
          <div
            className={cn(
              "flex justify-between text-xl font-bold text-[#171717] dark:text-neutral-100",
              !compact && "border-t border-[#898887] pt-3",
            )}
          >
            <span>{t("pages.cart.total")}</span>
            <span>{formatMoney(total ?? 0)}</span>
          </div>
        )}
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
  special = false,
  className,
}: {
  tier?: DiscountTier
  special?: boolean
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

  const label =
    special && tier.name
      ? `${tier.name} (${tier.percentage}%)`
      : t("pages.cart.benefit", { percentage: tier.percentage })

  return (
    <div className={cn("flex justify-between text-sm", className)}>
      <span className="text-[#737373] dark:text-neutral-400">{label}</span>
      <span className="text-[#15803D] font-normal">- {formatMoney(tier.discount)}</span>
    </div>
  )
}
