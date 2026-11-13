import type { ReactNode } from "react"

import { cn } from "@/lib/utils"

interface DashboardMetricProps {
  icon?: ReactNode
  label: string
  value: number | string
  variant?: "default" | "destructive"
  valueFirst?: boolean
  className?: string
}

export default function DashboardMetric({
  icon,
  label,
  value,
  variant = "default",
  valueFirst = false,
  className,
}: DashboardMetricProps) {
  const valueContent = (
    <p className="flex items-center justify-center gap-1 text-2xl font-semibold tracking-tight">
      {icon}
      {value}
    </p>
  )

  return (
    <div className={cn("min-w-0", valueFirst && "text-center", className)}>
      {valueFirst && valueContent}
      <p
        className={cn(
          valueFirst ? "text-sm" : "text-muted-foreground text-sm",
          variant === "destructive" && "text-destructive",
        )}
      >
        {label}
      </p>
      {!valueFirst && (
        <p className="mt-1 text-2xl font-semibold tracking-tight">{value}</p>
      )}
    </div>
  )
}
