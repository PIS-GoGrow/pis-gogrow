import type { ReactNode } from "react"

import { cn } from "@/lib/utils"

export default function Heading({
  title,
  description,
  eyebrow,
  actions,
  back,
  titleVariant = "default",
  compact = false,
  centered = false,
}: {
  title: string
  description?: string
  eyebrow?: string
  actions?: ReactNode
  back?: ReactNode
  titleVariant?: "default" | "prominent"
  compact?: boolean
  centered?: boolean
}) {
  return (
    <div className={cn("grid gap-4", compact ? "mb-4" : "mb-8")}>
      {back && !centered && <div className="flex">{back}</div>}
      <div
        className={cn(
          "flex flex-wrap items-end gap-4",
          centered ? "relative justify-center text-center" : "justify-between",
        )}
      >
        {back && centered && (
          <div className="absolute top-1/2 left-0 -translate-y-1/2">{back}</div>
        )}
        <div className="space-y-0.5">
          {eyebrow && (
            <p className="text-muted-foreground text-xs font-semibold tracking-wider uppercase">
              {eyebrow}
            </p>
          )}
          <h2
            className={cn(
              "tracking-tight",
              titleVariant === "prominent"
                ? "text-2xl font-bold"
                : "text-xl font-semibold",
            )}
          >
            {title}
          </h2>
          {description && (
            <p
              className={cn(
                "text-muted-foreground",
                titleVariant === "prominent" ? "text-base" : "text-sm",
              )}
            >
              {description}
            </p>
          )}
        </div>
        {actions && <div className="flex items-center gap-2">{actions}</div>}
      </div>
    </div>
  )
}
