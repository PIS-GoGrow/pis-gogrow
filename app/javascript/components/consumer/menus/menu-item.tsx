import { Plus } from "lucide-react"
import { useTranslation } from "react-i18next"

import { Button } from "@/components/ui/button"
import { cn } from "@/lib/utils"

export default function MenuItem({
  providerName,
  name,
  price,
  description,
  soldOut,
  ordersClosed = false,
  isPast = false,
  addedQuantity,
  onSelect,
}: {
  providerName: string
  name: string
  price: number
  description?: string | null
  soldOut: boolean
  ordersClosed?: boolean
  isPast?: boolean
  addedQuantity?: number
  onSelect?: () => void
}) {
  const { t } = useTranslation()
  const disabled = soldOut || ordersClosed || isPast

  return (
    <div
      className={cn(
        "border-border bg-card mb-3 flex items-center gap-4 rounded-xl border p-4",
        disabled && "opacity-50",
      )}
    >
      <div className="min-w-0 flex-1">
        <div className="mb-1 flex items-center gap-1.5">
          <span className="text-muted-foreground text-sm">{providerName}</span>
          {addedQuantity && (
            <span className="text-foreground text-xs">• Agregado</span>
          )}
          {ordersClosed && (
            <span className="text-destructive flex items-center gap-1 text-xs">
              <span className="bg-destructive inline-block size-1.5 rounded-full" />
              {t("pages.consumer_dashboard.index.orders_closed")}
            </span>
          )}
          {soldOut && (
            <span className="text-destructive flex items-center gap-1 text-xs">
              <span className="bg-destructive inline-block size-1.5 rounded-full" />
              Agotado
            </span>
          )}
        </div>
        <p className="font-semibold">
          {name} <span className="font-normal">| ${price}</span>
        </p>
        {description && (
          <p className="text-muted-foreground mt-1 line-clamp-2 text-sm">
            {description}
          </p>
        )}
      </div>
      <Button
        size="icon"
        variant="outline"
        disabled={disabled}
        onClick={onSelect}
        aria-label={`Agregar ${name}`}
        className={cn(
          "size-8 shrink-0 rounded-full",
          !addedQuantity &&
            "border-border bg-card text-foreground hover:bg-accent hover:text-accent-foreground",
          addedQuantity &&
            "border-primary bg-primary text-primary-foreground hover:border-primary hover:bg-primary hover:text-primary-foreground dark:border-primary dark:bg-primary dark:text-primary-foreground dark:hover:border-primary dark:hover:bg-primary dark:hover:text-primary-foreground",
        )}
      >
        {addedQuantity ?? <Plus aria-hidden="true" className="size-4" />}
      </Button>
    </div>
  )
}
