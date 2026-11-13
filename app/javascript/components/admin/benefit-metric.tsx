import { cn } from "@/lib/utils"

interface BenefitMetricProps {
  label: string
  value: string
  detail?: string
  className?: string
}

export default function BenefitMetric({
  label,
  value,
  detail,
  className,
}: BenefitMetricProps) {
  return (
    <div
      className={cn("bg-background rounded-xl border px-3 py-2.5", className)}
    >
      <p className="text-muted-foreground text-sm font-medium">{label}</p>
      <p className="mt-1 text-xl font-bold">{value}</p>
      {detail && <p className="text-muted-foreground text-sm">{detail}</p>}
    </div>
  )
}
