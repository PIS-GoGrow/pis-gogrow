import type { ReactNode } from "react"

import { cn } from "@/lib/utils"

export default function Heading({
  title,
  description,
  eyebrow,
  actions,
  back,
  titleVariant = "default",
}: {
  title: string
  description?: string
  eyebrow?: string
  actions?: ReactNode
  back?: ReactNode
  titleVariant?: "default" | "prominent"
}) {
  return (
    <div className="mb-8 grid gap-4">
      {back && <div className="flex">{back}</div>}
      <div className="flex flex-wrap items-end justify-between gap-4">
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
