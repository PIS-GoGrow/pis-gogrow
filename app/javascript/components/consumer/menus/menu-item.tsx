import { Plus } from "lucide-react"
import { useTranslation } from "react-i18next"

import AddedBadge from "@/components/consumer/menus/added-badge"
import FavoriteButton from "@/components/consumer/menus/favorite-button"
import StatusBadge from "@/components/status-badge"
import { Button } from "@/components/ui/button"
import { formatMoney } from "@/lib/money"
import { cn } from "@/lib/utils"

const counterStyles = {
  added:
    "border-blue-700 bg-blue-700 text-white hover:border-blue-700 hover:bg-blue-700 hover:text-white dark:border-blue-700 dark:bg-blue-700 dark:text-white dark:hover:border-blue-700 dark:hover:bg-blue-700 dark:hover:text-white",
  pending:
    "border-amber-500 bg-amber-500 text-white hover:border-amber-500 hover:bg-amber-500 hover:text-white dark:border-amber-500 dark:bg-amber-500 dark:text-white dark:hover:border-amber-500 dark:hover:bg-amber-500 dark:hover:text-white",
  confirmed:
    "border-green-600 bg-green-600 text-white hover:border-green-600 hover:bg-green-600 hover:text-white dark:border-green-600 dark:bg-green-600 dark:text-white dark:hover:border-green-600 dark:hover:bg-green-600 dark:hover:text-white",
}

export default function MenuItem({
  providerName,
  name,
  price,
  description,
  soldOut,
  ordersClosed = false,
  isPast = false,
  addedQuantity,
  pendingQuantity,
  confirmedQuantity,
  onSelect,
  favorite,
  onToggleFavorite,
}: {
  providerName: string
  name: string
  price: number
  description?: string | null
  soldOut: boolean
  ordersClosed?: boolean
  isPast?: boolean
  addedQuantity?: number
  pendingQuantity?: number
  confirmedQuantity?: number
  onSelect?: () => void
  favorite?: boolean
  onToggleFavorite?: () => void
}) {
  const { t } = useTranslation()
  const disabled = soldOut || ordersClosed || isPast
  // El contador vive dentro del botón que abre el carrito, así que muestra
  // sobre qué actúa el toque: primero el carrito y después lo ya pedido.
  const counter = (
    [
      { tone: "added", quantity: addedQuantity },
      { tone: "pending", quantity: pendingQuantity },
      { tone: "confirmed", quantity: confirmedQuantity },
    ] as const
  ).find(({ quantity }) => quantity)

  return (
    <div
      onClick={disabled ? undefined : onSelect}
      className={cn(
        "border-border bg-card mb-3 flex items-center gap-4 rounded-xl border p-4",
        disabled ? "opacity-50" : "cursor-pointer",
      )}
    >
      <div className="min-w-0 flex-1">
        <div className="mb-1 flex flex-wrap items-center gap-1.5">
          <span className="text-muted-foreground text-sm">{providerName}</span>
          {!!addedQuantity && <AddedBadge />}
          {!!pendingQuantity && (
            <StatusBadge status="pending" className="px-2 py-0.5" />
          )}
          {!!confirmedQuantity && (
            <StatusBadge status="confirmed" className="px-2 py-0.5" />
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
          {name} <span className="font-normal">| {formatMoney(price)}</span>
        </p>
        {description && (
          <p className="text-muted-foreground mt-1 line-clamp-2 text-sm">
            {description}
          </p>
        )}
      </div>
      {onToggleFavorite && (
        <FavoriteButton
          active={!!favorite}
          label={t(
            `pages.consumer_dashboard.index.favorites.${favorite ? "remove" : "add"}`,
            { name },
          )}
          onToggle={onToggleFavorite}
        />
      )}
      <Button
        size="icon"
        variant="outline"
        disabled={disabled}
        onClick={(e) => {
          e.stopPropagation()
          onSelect?.()
        }}
        aria-label={`Agregar ${name}`}
        className={cn(
          "size-8 shrink-0 rounded-full",
          counter
            ? counterStyles[counter.tone]
            : "border-border bg-card text-foreground hover:bg-accent hover:text-accent-foreground",
        )}
      >
        {counter?.quantity ?? <Plus aria-hidden="true" className="size-4" />}
      </Button>
    </div>
  )
}
