import { Plus } from "lucide-react"

import { Button } from "@/components/ui/button"
import { cn } from "@/lib/utils"

import type { CartItem, Schedule } from "./consumer-types"
import { money } from "./formatters"

interface Props {
  item: Schedule
  added?: CartItem
  openDetail: (item: Schedule) => void
}

export function MenuCard({ item, added, openDetail }: Props) {
  return (
    <article
      className={cn(
        "border-border bg-card relative min-h-[132px] rounded-lg border p-4 pr-14 md:min-h-32 md:p-5 md:pr-16",
        item.sold_out && "opacity-55",
      )}
    >
      <p className="text-muted-foreground flex items-center gap-2 text-[11px] md:text-xs">
        {item.menu.provider_name}
        {added && (
          <span className="bg-muted text-foreground rounded-full px-2 py-0.5 text-[9px]">
            • Agregado
          </span>
        )}
        {item.sold_out && (
          <span className="text-[10px] text-red-500">• Agotado</span>
        )}
      </p>
      <h3 className="mt-1 text-sm font-bold md:text-base md:font-medium">
        {item.menu.name}{" "}
        <span className="font-normal">| {money(item.menu.price)}</span>
      </h3>
      <p className="text-muted-foreground mt-1 line-clamp-2 text-[11px] leading-4 md:text-sm md:leading-5">
        {item.menu.description}
      </p>
      {item.sold_out ? (
        <span className="sr-only">Agotado</span>
      ) : (
        <Button
          type="button"
          variant="outline"
          size="icon"
          onClick={() => openDetail(item)}
          aria-label={`Agregar ${item.menu.name}`}
          className={cn(
            "absolute top-1/2 right-3 size-8 -translate-y-1/2 rounded-full",
            added && "border-blue-700 bg-blue-700 text-white",
          )}
        >
          {added ? (
            added.quantity
          ) : (
            <Plus aria-hidden="true" className="size-4" />
          )}
        </Button>
      )}
    </article>
  )
}
