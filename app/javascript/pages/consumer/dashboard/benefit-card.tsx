import { useTranslation } from "react-i18next"

import { Progress } from "@/components/ui/progress"
import { cn } from "@/lib/utils"
import type { ConsumerDashboardIndex } from "@/types"

interface Props {
  benefit: ConsumerDashboardIndex["benefit"]
  mobile?: boolean
}

export function BenefitCard({ benefit, mobile = false }: Props) {
  const { t } = useTranslation()
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
            {t("pages.consumer_dashboard.weekly_menu.consumption.title")}
          </span>
          <span className="rounded-full bg-white px-2 py-1 text-[14px] leading-5 font-medium text-[#737373] dark:bg-neutral-800 dark:text-neutral-300">
            {t("pages.consumer_dashboard.weekly_menu.consumption.this_week")}
          </span>
        </div>

        {/* Frame 71 */}
        <div className="flex items-end gap-1.5">
          <span className="text-[24px] leading-8 font-bold text-[#0A0A0A] dark:text-neutral-100">
            {benefit.used} de {benefit.limit}
          </span>
          <span className="text-[18px] leading-7 font-semibold text-[#0A0A0A] dark:text-neutral-100">
            {t(
              "pages.consumer_dashboard.weekly_menu.consumption.meals_ordered",
              { count: benefit.used },
            )}
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
