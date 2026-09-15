import { Plus } from "lucide-react"

import { Button } from "@/components/ui/button"
import { cn } from "@/lib/utils"
import type { ConsumerSchedule } from "@/types"

export default function MenuItem({
  schedule,
  isPast = false,
}: {
  schedule: ConsumerSchedule
  isPast?: boolean
}) {
  const { menu, amount } = schedule
  const soldOut = amount !== null && amount === 0
  const disabled = soldOut || isPast

  return (
    <div
      className={cn(
        "flex items-center gap-4 rounded-xl border p-4 mb-3",
        disabled && "opacity-50"
      )}
    >
      <div className="min-w-0 flex-1">
        <div className="mb-1 flex items-center gap-1.5">
          <span className="text-muted-foreground text-sm">{menu.provider.name}</span>
          {soldOut && (
            <span className="text-destructive flex items-center gap-1 text-xs">
              <span className="bg-destructive inline-block size-1.5 rounded-full" />
              Agotado
            </span>
          )}
        </div>
        <p className="font-semibold">
          {menu.name}{" "}
          <span className="font-normal">| ${menu.price}</span>
        </p>
        {menu.description && (
          <p className="text-muted-foreground mt-1 line-clamp-2 text-sm">
            {menu.description}
          </p>
        )}
      </div>
      <Button
        size="icon"
        variant="outline"
        disabled={disabled}
        className="size-8 shrink-0 rounded-full"
      >
        <Plus className="size-4" />
      </Button>
    </div>
  )
}
