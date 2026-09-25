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
        "flex flex-col justify-between gap-4 rounded-lg border border-[#E5E5E5] bg-[#F5F5F5] p-4 dark:border-neutral-800 dark:bg-neutral-900",
        mobile ? "w-full lg:hidden" : "w-full",
      )}
    >
      <div className="flex flex-col gap-3">
        {/* Frame 73 */}
        <div className="flex items-center justify-between gap-2">
          <span className="text-[16px] leading-6 font-medium text-[#737373] dark:text-neutral-400">
            Tu consumo
          </span>
          <span className="rounded-full bg-white px-2 py-1 text-[14px] leading-5 font-medium text-[#737373] dark:bg-neutral-800 dark:text-neutral-300">
            Esta semana
          </span>
        </div>

        {/* Frame 71 */}
        <div className="flex items-end gap-1.5">
          <span className="text-[24px] leading-8 font-bold text-[#0A0A0A] dark:text-neutral-100">
            {benefit.used} de {benefit.limit}
          </span>
          <span className="text-[18px] leading-7 font-semibold text-[#0A0A0A] dark:text-neutral-100">
            viandas pedidas
          </span>
        </div>
      </div>

      {/* Progressbar */}
      <Progress
        value={progress}
        className="h-2 w-full bg-[#171717]/20 dark:bg-white/20"
      />
    </div>
  )
}
