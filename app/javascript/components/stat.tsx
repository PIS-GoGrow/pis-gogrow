import type { ReactNode } from "react"

import {
  Card,
  CardAction,
  CardContent,
  CardDescription,
  CardHeader,
} from "@/components/ui/card"
import { cn } from "@/lib/utils"

interface StatProps {
  label: string
  value: ReactNode
  detail?: ReactNode
  badge?: ReactNode
  className?: string
}

export default function Stat({
  label,
  value,
  detail,
  badge,
  className,
}: StatProps) {
  return (
    <Card className={cn("bg-muted/50 gap-3 py-4", className)}>
      <CardHeader className="px-4">
        <CardDescription>{label}</CardDescription>
        {badge && <CardAction>{badge}</CardAction>}
      </CardHeader>
      <CardContent className="flex flex-wrap items-baseline gap-x-2 px-4">
        <strong className="text-2xl">{value}</strong>
        {detail && (
          <span className="text-muted-foreground text-sm">{detail}</span>
        )}
      </CardContent>
    </Card>
  )
}
