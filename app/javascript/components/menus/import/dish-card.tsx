import { Copy, Pencil, RefreshCw, TriangleAlert, Undo2, X } from "lucide-react"
import { useTranslation } from "react-i18next"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Separator } from "@/components/ui/separator"
import type { Dish, DishStatus } from "@/lib/menu-import"
import { formatMoney } from "@/lib/money"
import { cn } from "@/lib/utils"

// El estado se lee de un vistazo por el color del borde y del badge, manteniendo
// consistencia entre el modo claro y oscuro.
export const STATUS_STYLES: Record<
  DishStatus,
  { border: string; badge: string; dot: string }
> = {
  new: {
    border: "border-green-200 dark:border-green-900",
    badge: "bg-green-50 text-green-700 dark:bg-green-950 dark:text-green-300",
    dot: "bg-green-500",
  },
  updated: {
    border: "border-green-200 dark:border-green-900",
    badge: "bg-green-50 text-green-700 dark:bg-green-950 dark:text-green-300",
    dot: "bg-green-500",
  },
  error: {
    border: "border-red-200 dark:border-red-900",
    badge: "bg-red-50 text-red-700 dark:bg-red-950 dark:text-red-300",
    dot: "bg-red-500",
  },
  exists: {
    border: "border-amber-200 dark:border-amber-900",
    badge: "bg-amber-50 text-amber-700 dark:bg-amber-950 dark:text-amber-300",
    dot: "bg-amber-500",
  },
}

interface DishCardProps {
  dish: Dish
  status: DishStatus
  onRemove: () => void
  onEdit: () => void
  onDuplicate: () => void
  onUpdate: () => void
  onReset: () => void
}

export default function DishCard({
  dish,
  status,
  onRemove,
  onEdit,
  onDuplicate,
  onUpdate,
  onReset,
}: DishCardProps) {
  const { t } = useTranslation()
  const key = "pages.provider_menu_imports.new.card"
  const style = STATUS_STYLES[status]

  return (
    <div className={cn("rounded-xl border p-4", style.border)}>
      <div className="flex items-start justify-between gap-3">
        <span className="font-medium">
          {dish.name.trim() || t(`${key}.unnamed`)}
        </span>

        <Badge
          variant="outline"
          className={cn("gap-1.5 border-transparent font-medium", style.badge)}
        >
          <span
            aria-hidden="true"
            className={cn("size-1.5 rounded-full", style.dot)}
          />
          {t(`${key}.${status}`)}
        </Badge>
      </div>

      {dish.description.trim() && (
        <p className="text-muted-foreground mt-1 text-sm">{dish.description}</p>
      )}

      <p className="text-muted-foreground mt-2 text-xs">
        {dish.price.trim()
          ? t(`${key}.price`, { price: formatMoney(dish.price) })
          : t(`${key}.no_price`)}
      </p>

      {status === "error" && (
        <p className="mt-2 flex items-start gap-1.5 text-sm text-red-700 dark:text-red-400">
          <TriangleAlert
            aria-hidden="true"
            className="mt-0.5 size-4 shrink-0"
          />
          <span>{dish.errors.join(" ")}</span>
        </p>
      )}

      {status === "exists" && (
        <p className="mt-2 flex items-start gap-1.5 text-sm text-amber-700 dark:text-amber-400">
          <TriangleAlert
            aria-hidden="true"
            className="mt-0.5 size-4 shrink-0"
          />
          <span>{t(`${key}.exists_warning`)}</span>
        </p>
      )}

      <Separator className="my-3" />

      <div className="flex items-center justify-between gap-2">
        {status === "exists" ? (
          <>
            <Button variant="ghost" size="sm" onClick={onEdit}>
              <Pencil aria-hidden="true" />
              {t(`${key}.edit`)}
            </Button>
            <Button variant="ghost" size="sm" onClick={onDuplicate}>
              <Copy aria-hidden="true" />
              {t(`${key}.duplicate`)}
            </Button>
            <Button variant="ghost" size="sm" onClick={onUpdate}>
              <RefreshCw aria-hidden="true" />
              {t(`${key}.update`)}
            </Button>
          </>
        ) : (
          <>
            <Button variant="ghost" size="sm" onClick={onRemove}>
              <X aria-hidden="true" />
              {t(`${key}.remove`)}
            </Button>
            <Button variant="ghost" size="sm" onClick={onEdit}>
              <Pencil aria-hidden="true" />
              {t(`${key}.edit`)}
            </Button>
            {status === "updated" && (
              <Button variant="ghost" size="sm" onClick={onReset}>
                <Undo2 aria-hidden="true" />
                {t(`${key}.reset`)}
              </Button>
            )}
          </>
        )}
      </div>
    </div>
  )
}
