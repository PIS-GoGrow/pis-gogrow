import { useEffect, useMemo, useState } from "react"
import { ChevronLeft, Star, TicketPercent } from "lucide-react"
import { useTranslation } from "react-i18next"

import AddedBadge from "@/components/consumer/menus/added-badge"
import { BottomAction, MobileCard } from "@/components/consumer/mobile-card"
import OptionChoices from "@/components/menus/option-choices"
import { QuantityInput } from "@/components/quantity-input"
import { Button } from "@/components/ui/button"
import { Textarea } from "@/components/ui/textarea"
import { Checkbox } from "@/components/ui/checkbox"
import { Field, FieldContent, FieldLabel } from "@/components/ui/field"
import { formatMoney } from "@/lib/money"

import type { CartItem, Schedule, Selections } from "./consumer-types"
import { OrderSummary } from "./order-summary"
import type { PricedLine } from "./pricing"
import { cartPricedItem, lastUnitsLine, priceItems } from "./pricing"
import type { ConsumerDashboardIndex } from "@/types"

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
  editingCartId?: string | null
  onRemove?: () => void
  add: (benefits: number[]) => void
  benefit: ConsumerDashboardIndex["benefit"]
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
  benefit,
}: Props) {
  const { t } = useTranslation()
  const [line, setLine] = useState<PricedLine | null>(null)
  // Al principio, todos los beneficios están activados
  const [benefitIds, setBenefitIds] = useState<number[]>(benefit.specials.map((b) => b.id))

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
          cartPricedItem([...cartToPrice, { ...item, quantity, benefits: benefitIds }]),
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
  }, [cart, item, inCart, isEditing, cartWithoutCurrent, otherInCart, item.id, item.date, item.menu.price, quantity, benefitIds])

  function setChecked(benefitId: number) {
    if (benefitIds.includes(benefitId))
      setBenefitIds(benefitIds.filter((b) => b !== benefitId))
    else
      setBenefitIds(benefitIds.concat([benefitId]))
  }

  const reviews = item.menu.reviews
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
        <div className="flex justify-between text-sm font-medium">
          <h2>Opiniones del plato</h2>
          <span className="text-xs leading-4">
            <Star className="fill-foreground mr-1 inline size-3" />
            {reviews[0]?.rating ?? "4.8"}
          </span>
        </div>
        <div className="mt-3 flex gap-4 overflow-x-auto">
          {(reviews.length
            ? reviews
            : [
                {
                  id: 0,
                  rating: 5,
                  description:
                    "Los sorrentinos llegaron muy ricos y con mucho sabor.",
                },
              ]
          ).map((review, index) => (
            <article
              key={review.id}
              className="border-border bg-muted flex h-[136px] w-[280px] shrink-0 flex-col gap-3 rounded-md border p-4"
            >
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-sm leading-5 font-medium">
                    {index ? "Pedro" : "Lucía"}
                  </span>
                  <span className="text-muted-foreground text-xs leading-4">
                    28/07/26
                  </span>
                </div>
                <p className="text-xs leading-4">
                  {"★".repeat(Math.round(review.rating ?? 5))}
                </p>
              </div>
              <p className="text-xs leading-4">{review.description}</p>
            </article>
          ))}
        </div>
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
      <section className="border-border border-b py-4 text-sm grid gap-2">
        {
          benefit.specials.filter((benefit) => {
            return benefit.remaining === null || benefit.remaining > 0
          }).map((benefit) => (
            <div key={benefit.id} className="flex justify-between">
              <div className="flex">
                <TicketPercent color="#29944c" className="mr-2" size="20"/>
                <p>{benefit.name} ({benefit.percentage}% off)</p>
              </div>

              <Field orientation="horizontal" className="max-w-fit">
                <Checkbox
                  id={`benefit-checkbox-${benefit.id}`}
                  name={`benefit-checkbox-${benefit.id}`}
                  onCheckedChange={() => setChecked(benefit.id)}
                  checked={benefitIds.includes(benefit.id)}
                />

                <FieldContent className="max-w-fit">
                  <FieldLabel htmlFor={`benefit-checkbox-${benefit.id}`}>
                    Aplicar
                  </FieldLabel>
                </FieldContent>
              </Field>
            </div>
          ))
        }
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
          onClick={() => add(benefitIds)}
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
