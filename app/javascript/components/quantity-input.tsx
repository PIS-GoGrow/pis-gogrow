import { Minus, Plus, Trash2 } from "lucide-react"

import { Button } from "@/components/ui/button"
import { cn } from "@/lib/utils"

interface Props {
  value: number
  min?: number
  max: number
  onChange: (value: number) => void
  // Versión baja (h-8) para listas, como el carrito.
  size?: "default" | "sm"
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
        size === "sm" ? "h-8" : "h-12",
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
        className="hover:bg-primary hover:text-primary-foreground dark:hover:!bg-primary dark:hover:!text-primary-foreground h-full rounded-r-none"
      >
        {removing ? (
          <Trash2 aria-hidden="true" className="size-3.5" />
        ) : (
          <Minus aria-hidden="true" className="size-3" />
        )}
      </Button>
      <span className="min-w-6 text-center">{value}</span>
      <Button
        type="button"
        variant="ghost"
        size="icon"
        aria-label={increaseLabel}
        disabled={disabled || value >= max}
        onClick={() => onChange(Math.min(max, value + 1))}
        className="hover:bg-primary hover:text-primary-foreground dark:hover:!bg-primary dark:hover:!text-primary-foreground h-full rounded-l-none"
      >
        <Plus aria-hidden="true" className="size-3" />
      </Button>
    </div>
  )
}
