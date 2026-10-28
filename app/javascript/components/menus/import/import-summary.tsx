import { useTranslation } from "react-i18next"

import type { DishStatus } from "@/lib/menu-import"
import { cn } from "@/lib/utils"

const STYLES: Record<DishStatus, string> = {
  new: "bg-green-50 text-green-700 dark:bg-green-950 dark:text-green-400",
  updated: "bg-green-50 text-green-700 dark:bg-green-950 dark:text-green-400",
  error: "bg-red-50 text-red-700 dark:bg-red-950 dark:text-red-400",
  exists: "bg-amber-50 text-amber-700 dark:bg-amber-950 dark:text-amber-400",
}

// En el mismo orden en que el proveedor los va a resolver: primero lo que está
// listo, después lo que lo frena y por último lo que puede decidir.
const ORDER: DishStatus[] = ["new", "updated", "error", "exists"]

interface ImportSummaryProps {
  counts: Record<DishStatus, number>
}

export default function ImportSummary({ counts }: ImportSummaryProps) {
  const { t } = useTranslation()
  const key = "pages.provider_menu_imports.new.summary"
  const shown = ORDER.filter((status) => counts[status] > 0)

  if (shown.length === 0) return null

  return (
    <div className="flex flex-col gap-2">
      <span className="text-muted-foreground text-xs">{t(`${key}.title`)}</span>
      <div className="flex flex-wrap gap-2">
        {shown.map((status) => (
          <span
            key={status}
            className={cn(
              "rounded-full px-2.5 py-1 text-xs font-medium",
              STYLES[status],
            )}
          >
            {t(`${key}.${status}`, { count: counts[status] })}
          </span>
        ))}
      </div>
    </div>
  )
}
