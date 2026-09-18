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
        "border-border bg-muted/50 p-4",
        mobile
          ? "flex min-h-32 flex-col justify-between rounded-lg md:hidden"
          : "rounded-2xl shadow-sm",
      )}
    >
      <div className="text-muted-foreground flex justify-between text-[11px] md:text-sm">
        <span>Tu beneficio</span>
        <span className="bg-background rounded-full px-3 py-1">
          Esta semana
        </span>
      </div>
      <p className="mt-2 text-sm font-bold md:text-lg">
        {benefit.used} de {benefit.limit} viandas pedidas
      </p>
      <Progress value={progress} className="bg-muted mt-3 h-1.5" />
    </div>
  )
}
