import { Progress } from "@/components/ui/progress"
import { cn } from "@/lib/utils"
import type { ConsumerDashboardIndex } from "@/types"

interface Props {
  benefit: ConsumerDashboardIndex["benefit"]
  mobile?: boolean
}

export function BenefitCard({ benefit, mobile = false }: Props) {
  const progress = Math.min(
    100,
    (benefit.used / Math.max(benefit.limit, 1)) * 100,
  )

  return (
    <div
      className={cn(
        "border border-[#e5e5e5] bg-[#f5f5f5] p-4",
        mobile
          ? "flex min-h-32 flex-col justify-between rounded-lg md:hidden"
          : "rounded-2xl shadow-sm",
      )}
    >
      <div className="flex justify-between text-[11px] text-[#777] md:text-sm">
        <span>Tu beneficio</span>
        <span className="rounded-full bg-white px-3 py-1">Esta semana</span>
      </div>
      <p className="mt-2 text-sm font-bold md:text-lg">
        {benefit.used} de {benefit.limit} viandas pedidas
      </p>
      <Progress value={progress} className="mt-3 h-1.5 bg-[#ccc]" />
    </div>
  )
}
