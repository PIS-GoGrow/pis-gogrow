import { ChevronLeft, Star } from "lucide-react"
import { useEffect, useMemo, useState } from "react"
import { useTranslation } from "react-i18next"

import AddedBadge from "@/components/consumer/menus/added-badge"
import { BottomAction, MobileCard } from "@/components/consumer/mobile-card"
import OptionChoices from "@/components/menus/option-choices"
import { QuantityInput } from "@/components/quantity-input"
import { Button } from "@/components/ui/button"
import { Textarea } from "@/components/ui/textarea"
import { formatShortDate } from "@/lib/dates"
import { formatMoney } from "@/lib/money"

import type { CartItem, Schedule, Selections } from "./consumer-types"
import { OrderSummary } from "./order-summary"
import type { PricedLine } from "./pricing"
import { cartPricedItem, lastUnitsLine, priceItems } from "./pricing"

interface Props {
  item: Schedule
  quantity: number
  setQuantity: (value: number) => void
  notes: string
  setNotes: (value: string) => void
  selections: Selections
  setSelections: (value: Selections) => void
  cart: CartItem[]
  back: () => void
  add: () => void
  editingCartId?: string | null
  onRemove?: () => void
}

export function DishDetail({
  item,
  quantity,
  setQuantity,
  notes,
  setNotes,
  selections,
  setSelections,
  cart,
  back,
  add,
  editingCartId,
  onRemove,
}: Props) {
  const { t } = useTranslation()
  const [line, setLine] = useState<PricedLine | null>(null)

  const isEditing = Boolean(editingCartId ?? onRemove)

  const inCart =
    cartPricedItem(cart).find((i) => item.id === i.schedule_id)?.quantity ?? 0

  const cartWithoutCurrent = useMemo(
    () =>
      editingCartId
        ? cart.filter((c) => c.cartId !== editingCartId)
        : cart.filter((c) => c.id !== item.id),
    [cart, editingCartId, item.id],
  )

  const otherInCart = useMemo(
    () =>
      cartPricedItem(cartWithoutCurrent).find((i) => item.id === i.schedule_id)
        ?.quantity ?? 0,
    [cartWithoutCurrent, item.id],
  )

  const maxQuantity = item.remaining - (isEditing ? otherInCart : inCart)

  useEffect(() => {
    let cancelled = false

    // Esperar 200 milisegundos para hacer la request, por si el usuario toca varias veces
    // seguidas los botones de + o -.
    const timeout = setTimeout(async () => {
      try {
        const cartToPrice = isEditing ? cartWithoutCurrent : cart
        const result = await priceItems(
          cartPricedItem([...cartToPrice, { ...item, quantity }]),
        )
        if (cancelled || !result?.lines) return

        const preLine = result.lines[String(item.id)]
        const totalUnits = (isEditing ? otherInCart : inCart) + quantity

        setLine(preLine ? lastUnitsLine(totalUnits, quantity, preLine) : null)
      } finally {
        // No hacer nada
      }
    }, 200)

    return () => {
      cancelled = true
      clearTimeout(timeout)
    }
  }, [
    cart,
    item,
    inCart,
    isEditing,
    cartWithoutCurrent,
    otherInCart,
    item.id,
    item.date,
    item.menu.price,
    quantity,
  ])

  const reviews = item.menu.reviews
  const ratingAverage = item.menu.rating_average
  const ratingCount = item.menu.rating_count
  const choicesMissing = item.menu.option_groups.some(
    (group) => group.required && !selections[group.id]?.length,
  )
  const addDisabled = item.sold_out || item.orders_closed || choicesMissing

  return (
    <MobileCard>
      <Button
        type="button"
        variant="ghost"
        size="icon"
        onClick={back}
        aria-label="Volver"
        className="mb-3"
      >
        <ChevronLeft aria-hidden="true" className="size-5" />
      </Button>
      <div className="flex items-center justify-between gap-2">
        <p className="text-muted-foreground text-xs">
          {item.menu.provider_name}
        </p>
        {inCart > 0 && <AddedBadge />}
      </div>
      <h1 className="mt-1 text-xl font-bold">{item.menu.name}</h1>
      <p className="text-muted-foreground mt-2 text-xs leading-5">
        {item.menu.description}
      </p>
      <p className="mt-1 font-bold">{formatMoney(item.menu.price)}</p>
      {item.orders_closed && (
        <p className="text-destructive mt-3 text-sm">
          {t("pages.consumer_dashboard.index.orders_closed")}
        </p>
      )}
      {item.menu.option_groups.map((group) => (
        <OptionChoices
          key={group.id}
          group={group}
          values={selections[group.id] ?? []}
          setValues={(values) =>
            setSelections({ ...selections, [group.id]: values })
          }
        />
      ))}
      <section className="border-border border-b py-5">
        <div className="flex items-center justify-between text-sm font-medium">
          <h2>{t("pages.consumer_dashboard.index.reviews.title")}</h2>
          {ratingCount > 0 && ratingAverage !== null && (
            <span className="text-xs leading-4">
              <Star className="fill-foreground mr-1 inline size-3" />
              {ratingAverage.toFixed(1)} ({ratingCount})
            </span>
          )}
        </div>
        {ratingCount > 0 ? (
          <div className="mt-3 flex gap-4 overflow-x-auto">
            {reviews.map((review) => (
              <article
                key={review.id}
                className="border-border bg-muted flex min-h-[136px] w-[280px] shrink-0 flex-col gap-3 rounded-md border p-4"
              >
                <div className="space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="text-sm leading-5 font-medium">
                      {review.author ??
                        t("pages.consumer_dashboard.index.reviews.anonymous")}
                    </span>
                    <span className="text-muted-foreground text-xs leading-4">
                      {formatShortDate(review.created_at)}
                    </span>
                  </div>
                  <p className="text-xs leading-4">
                    {"★".repeat(review.rating)}
                    <span className="text-muted-foreground">
                      {"★".repeat(5 - review.rating)}
                    </span>
                  </p>
                </div>
                {review.description && (
                  <p className="text-xs leading-4">{review.description}</p>
                )}
              </article>
            ))}
          </div>
        ) : (
          <p className="text-muted-foreground mt-3 text-xs leading-5">
            {t("pages.consumer_dashboard.index.reviews.empty")}
          </p>
        )}
      </section>
      <section className="border-border border-b py-4">
        <label htmlFor="notes" className="text-xs font-semibold">
          Notas para este plato
        </label>
        <Textarea
          id="notes"
          maxLength={140}
          value={notes}
          onChange={(event) => setNotes(event.target.value)}
          placeholder="Escribí las notas que necesites..."
          className="mt-3 field-sizing-fixed h-20 w-full max-w-full min-w-0 resize-none rounded-lg p-3 text-xs"
        />
        <p className="text-muted-foreground text-right text-[10px]">
          {notes.length}/140
        </p>
      </section>
      <OrderSummary
        loading={false}
        subtotal={line?.subtotal}
        total={line?.total}
        tiers={line?.tiers}
      />
      <BottomAction className="flex">
        <QuantityInput
          value={quantity}
          max={maxQuantity}
          onChange={setQuantity}
          onRemove={onRemove}
        />
        <Button
          disabled={addDisabled}
          onClick={add}
          className="bg-primary text-primary-foreground hover:bg-primary/90 disabled:bg-muted disabled:text-muted-foreground h-12 flex-1 rounded-lg disabled:opacity-100"
        >
          {isEditing
            ? t("pages.consumer_dashboard.index.modify")
            : t("pages.consumer_dashboard.index.add")}
        </Button>
      </BottomAction>
    </MobileCard>
  )
}
