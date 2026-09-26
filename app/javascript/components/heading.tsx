import type { ReactNode } from "react"

export default function Heading({
  title,
  description,
  eyebrow,
  actions,
  back,
}: {
  title: string
  description?: string
  eyebrow?: string
  actions?: ReactNode
  back?: ReactNode
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
          <h2 className="text-xl font-semibold tracking-tight">{title}</h2>
          {description && (
            <p className="text-muted-foreground text-sm">{description}</p>
          )}
        </div>
        {actions && <div className="flex items-center gap-2">{actions}</div>}
      </div>
    </div>
  )
}
