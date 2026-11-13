import type { ReactNode } from "react"

import { cn } from "@/lib/utils"

export default function Heading({
  title,
  description,
  eyebrow,
  badge,
  actions,
  back,
  titleVariant = "default",
  compact = false,
  centered = false,
  mobileCentered = false,
  actionsCentered = false,
  mobileBack = false,
}: {
  title: string
  description?: string
  eyebrow?: string
  badge?: ReactNode
  actions?: ReactNode
  back?: ReactNode
  titleVariant?: "default" | "prominent"
  compact?: boolean
  centered?: boolean
  mobileCentered?: boolean
  actionsCentered?: boolean
  mobileBack?: boolean
}) {
  return (
    <div className={cn("grid gap-4", compact ? "mb-4" : "mb-8")}>
      {back && !centered && !mobileCentered && (
        <div className={cn("flex", mobileBack && "md:hidden")}>{back}</div>
      )}

      {back && mobileCentered && !mobileBack && (
        <div className="hidden md:flex">{back}</div>
      )}
      <div
        className={cn(
          "flex gap-4",
          actionsCentered ? "items-center" : "flex-wrap items-end",
          centered
            ? "relative justify-center text-center"
            : mobileCentered
              ? "relative justify-center text-center md:justify-between md:text-left"
              : "justify-between",
        )}
      >
        {back && centered && (
          <div
            className={cn(
              "absolute top-1/2 left-0 -translate-y-1/2",
              mobileBack && "md:hidden",
            )}
          >
            {back}
          </div>
        )}

        {back && mobileCentered && (
          <div className="absolute top-1/2 left-0 -translate-y-1/2 md:hidden">
            {back}
          </div>
        )}
        <div className={cn("space-y-0.5", actionsCentered && "min-w-0")}>
          {eyebrow && (
            <p className="text-muted-foreground text-xs font-semibold tracking-wider uppercase">
              {eyebrow}
            </p>
          )}
          <div className="flex items-center gap-2">
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
            {badge}
          </div>
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
