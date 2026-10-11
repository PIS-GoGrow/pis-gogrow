import { ChevronLeft, Star } from "lucide-react"
import { useTranslation } from "react-i18next"

import { BottomAction, MobileCard } from "@/components/consumer/mobile-card"
import OptionChoices from "@/components/menus/option-choices"
import { QuantityInput } from "@/components/quantity-input"
import { Button } from "@/components/ui/button"
import { Textarea } from "@/components/ui/textarea"
import { cn } from "@/lib/utils"

import type { CartItem, Schedule, Selections } from "./consumer-types"
import { money } from "./formatters"
import { OrderSummary } from "./order-summary"
import { type Benefit, cartPricedItem, priceItems } from "./pricing"

interface Props {
  item: Schedule
  quantity: number
  setQuantity: (value: number) => void
  notes: string
  setNotes: (value: string) => void
  selections: Selections
  setSelections: (value: Selections) => void
  benefit: Benefit
  cart: CartItem[]
  back: () => void
  add: () => void
}

export function DishDetail({
  item,
  quantity,
  setQuantity,
  notes,
  setNotes,
  selections,
  setSelections,
  benefit,
  cart,
  back,
  add,
}: Props) {
  const { t } = useTranslation()
  // El plato se agrega al final del carrito, así que lo que ya está ahí gasta
  // primero el cupo y los usos de los beneficios.
  const pricing = priceItems(
    [
      ...cart.map(cartPricedItem),
      { key: "", date: item.date, price: item.menu.price, quantity },
    ],
    benefit,
  )
  const line = pricing.lines[""]
  const reviews = item.menu.reviews
  // Cada grupo que el plato ofrece tiene que quedar elegido antes de agregarlo.
  const choicesMissing = item.menu.option_groups.some(
    (group) => !selections[group.id]?.length,
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
        className="mb-3 size-9 rounded-[10px]"
      >
        <ChevronLeft aria-hidden="true" className="size-4" />
      </Button>
      <p className="text-muted-foreground text-base font-medium">{item.menu.provider_name}</p>
      <h1 className="mt-1 text-2xl font-bold">{item.menu.name}</h1>
      <p className="text-muted-foreground mt-2 text-base leading-6">
        {item.menu.description}
      </p>
      <p className="mt-1 text-xl font-bold">{money(item.menu.price)}</p>
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
      <section className="border-border border-b py-6">
        <div className="flex items-center justify-between">
          <h2 className="text-base font-semibold">Opiniones del plato</h2>
          <span className="flex items-center gap-1 text-sm font-semibold">
            <Star className="fill-foreground inline size-4" />
            {reviews[0]?.rating ?? "4.8"}
          </span>
        </div>
        <div className="mt-4 flex gap-4 overflow-x-auto">
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
              className="border-border bg-muted flex h-[136px] w-[280px] shrink-0 flex-col gap-3 rounded-lg border p-4"
            >
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-sm font-medium">
                    {index ? "Pedro" : "Lucía"}
                  </span>
                  <span className="text-muted-foreground text-xs font-medium">
                    28/07/26
                  </span>
                </div>
                <div className="flex items-center gap-0.5">
                  {Array.from({ length: 5 }).map((_, i) => (
                    <Star
                      key={i}
                      className={cn(
                        "size-4",
                        i < Math.round(review.rating ?? 5)
                          ? "fill-foreground text-foreground"
                          : "text-muted-foreground opacity-25",
                      )}
                    />
                  ))}
                </div>
              </div>
              <p className="text-xs leading-4">{review.description}</p>
            </article>
          ))}
        </div>
      </section>
      <section className="border-border border-b py-6">
        <label htmlFor="notes" className="text-base font-semibold">
          Notas para este plato
        </label>
        <Textarea
          id="notes"
          maxLength={140}
          value={notes}
          onChange={(event) => setNotes(event.target.value)}
          placeholder="Escribe las notas que necesites..."
          className="mt-3 h-[87px] resize-none rounded-lg p-3 text-base placeholder:text-muted-foreground"
        />
        <p className="text-muted-foreground mt-2 text-right text-sm">
          {notes.length}/140
        </p>
      </section>
      <OrderSummary
        subtotal={line.subtotal}
        total={line.total}
        tiers={line.tiers}
      />
      <BottomAction className="flex gap-3">
        <QuantityInput
          value={quantity}
          max={item.remaining}
          onChange={setQuantity}
        />
        <Button
          disabled={addDisabled}
          onClick={add}
          className="bg-primary text-primary-foreground hover:bg-primary/90 disabled:bg-muted disabled:text-muted-foreground h-12 flex-1 rounded-[10px] text-base font-medium disabled:opacity-50"
        >
          Agregar
        </Button>
      </BottomAction>
    </MobileCard>
  )
}
