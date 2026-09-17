import { Plus } from "lucide-react"

import { Button } from "@/components/ui/button"
import { cn } from "@/lib/utils"

export default function MenuItem({
  providerName,
  name,
  price,
  description,
  soldOut,
  isPast = false,
  addedQuantity,
  onSelect,
}: {
  providerName: string
  name: string
  price: number
  description?: string | null
  soldOut: boolean
  isPast?: boolean
  addedQuantity?: number
  onSelect?: () => void
}) {
  const disabled = soldOut || isPast

  return (
    <div
      className={cn(
        "mb-3 flex items-center gap-4 rounded-xl border p-4",
        disabled && "opacity-50",
      )}
    >
      <div className="min-w-0 flex-1">
        <div className="mb-1 flex items-center gap-1.5">
          <span className="text-muted-foreground text-sm">{providerName}</span>
          {addedQuantity && (
            <span className="text-xs text-blue-600">• Agregado</span>
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
            "border-[#e5e5e5] bg-white text-black hover:bg-white hover:text-black dark:border-[#e5e5e5] dark:bg-white dark:text-black dark:hover:bg-white dark:hover:text-black",
          addedQuantity &&
            "border-blue-700 bg-blue-700 text-white hover:border-blue-700 hover:bg-blue-700 hover:text-white dark:border-blue-700 dark:bg-blue-700 dark:text-white dark:hover:bg-blue-700",
        )}
      >
        {addedQuantity ?? <Plus aria-hidden="true" className="size-4" />}
      </Button>
    </div>
  )
}
