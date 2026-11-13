import { Minus, Plus, Trash2 } from "lucide-react"

import { Button } from "@/components/ui/button"
import { cn } from "@/lib/utils"

interface Props {
  value: number
  min?: number
  max: number
  onChange: (value: number) => void
  // Versión baja (h-8 o h-7) para listas, como el carrito.
  size?: "default" | "sm" | "compact"
  // Si viene, al llegar al mínimo el "−" pasa a ser un tacho que quita el ítem.
  onRemove?: () => void
  disabled?: boolean
  decreaseLabel?: string
  increaseLabel?: string
  removeLabel?: string
}

export function QuantityInput({
  value,
  min = 1,
  max,
  onChange,
  size = "default",
  onRemove,
  disabled = false,
  decreaseLabel = "Quitar uno",
  increaseLabel = "Agregar uno",
  removeLabel = "Quitar",
}: Props) {
  const removing = !!onRemove && value <= min

  return (
    <div
      className={cn(
        "bg-secondary text-secondary-foreground flex w-fit items-center rounded-lg",
        size === "compact" ? "h-7 text-xs" : size === "sm" ? "h-8 text-sm" : "h-12",
      )}
    >
      <Button
        type="button"
        variant="ghost"
        size="icon"
        aria-label={removing ? removeLabel : decreaseLabel}
        disabled={disabled || (value <= min && !onRemove)}
        onClick={() =>
          removing ? onRemove?.() : onChange(Math.max(min, value - 1))
        }
        className={cn(
          "hover:bg-secondary/80 hover:text-secondary-foreground dark:hover:bg-secondary/80 h-full rounded-r-none",
          size === "compact" && "size-7 px-1.5",
        )}
      >
        {removing ? (
          <Trash2 aria-hidden="true" className={size === "compact" ? "size-3" : "size-3.5"} />
        ) : (
          <Minus aria-hidden="true" className={size === "compact" ? "size-2.5" : "size-3"} />
        )}
      </Button>
      <span className={cn("text-center", size === "compact" ? "min-w-4 px-0.5 font-medium" : "min-w-6")}>
        {value}
      </span>
      <Button
        type="button"
        variant="ghost"
        size="icon"
        aria-label={increaseLabel}
        disabled={disabled || value >= max}
        onClick={() => onChange(Math.min(max, value + 1))}
        className={cn(
          "hover:bg-secondary/80 hover:text-secondary-foreground dark:hover:bg-secondary/80 h-full rounded-l-none",
          size === "compact" && "size-7 px-1.5",
        )}
      >
        <Plus aria-hidden="true" className={size === "compact" ? "size-2.5" : "size-3"} />
      </Button>
    </div>
  )
}
