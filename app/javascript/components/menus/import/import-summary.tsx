import { useTranslation } from "react-i18next"

import { STATUS_STYLES } from "@/components/menus/import/dish-card"
import { Badge } from "@/components/ui/badge"
import type { DishStatus } from "@/lib/menu-import"
import { cn } from "@/lib/utils"

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
          <Badge
            key={status}
            variant="outline"
            className={cn(
              "border-transparent font-medium",
              STATUS_STYLES[status].badge,
            )}
          >
            {t(`${key}.${status}`, { count: counts[status] })}
          </Badge>
        ))}
      </div>
    </div>
  )
}
