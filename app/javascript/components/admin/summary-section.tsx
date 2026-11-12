import { Link } from "@inertiajs/react"
import { ChevronRight } from "lucide-react"
import type { ReactNode } from "react"

import HeadingSmall from "@/components/heading-small"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { cn } from "@/lib/utils"

interface SummarySectionProps {
  id: string
  title: string
  action?: { label: string; href: string }
  children: ReactNode
}

export function SummarySection({
  id,
  title,
  action,
  children,
}: SummarySectionProps) {
  return (
    <section aria-labelledby={id} className="space-y-3">
      <div className="flex min-h-8 items-center justify-between">
        <div id={id}>
          <HeadingSmall title={title} />
        </div>
        {action && (
          <Button asChild variant="ghost" size="icon-sm" className="group">
            <Link href={action.href} aria-label={action.label}>
              <ChevronRight
                className="size-4 transition-transform group-hover:translate-x-0.5"
                aria-hidden="true"
              />
            </Link>
          </Button>
        )}
      </div>
      {children}
    </section>
  )
}

export function SummaryList({ children }: { children: ReactNode }) {
  return (
    <Card className="gap-0 divide-y rounded-lg py-0 shadow-none">
      {children}
    </Card>
  )
}

export function SummaryRow({
  className,
  children,
}: {
  className?: string
  children: ReactNode
}) {
  return (
    <div className={cn("flex items-center gap-3 px-4 py-3", className)}>
      {children}
    </div>
  )
}
