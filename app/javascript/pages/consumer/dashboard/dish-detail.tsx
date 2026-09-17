import { ChevronLeft, Star } from "lucide-react"

import { QuantityInput } from "@/components/quantity-input"
import { Button } from "@/components/ui/button"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { Textarea } from "@/components/ui/textarea"

import type { Schedule } from "./consumer-types"
import { money } from "./formatters"
import { OrderSummary } from "./order-summary"

interface Props {
  item: Schedule
  quantity: number
  setQuantity: (value: number) => void
  notes: string
  setNotes: (value: string) => void
  filling: string
  setFilling: (value: string) => void
  sauce: string
  setSauce: (value: string) => void
  percentage: number
  back: () => void
  add: () => void
}

export function DishDetail({
  item,
  quantity,
  setQuantity,
  notes,
  setNotes,
  filling,
  setFilling,
  sauce,
  setSauce,
  percentage,
  back,
  add,
}: Props) {
  const subtotal = item.menu.price * quantity
  const discount = (subtotal * percentage) / 100
  const reviews = item.menu.reviews
  const choicesMissing =
    (item.menu.fillings.length > 0 && !filling) ||
    (item.menu.sauces.length > 0 && !sauce)
  const addDisabled = item.sold_out || choicesMissing

  return (
    <div className="mx-auto min-h-screen max-w-3xl bg-white px-6 pt-6 pb-28 md:my-8 md:min-h-0 md:rounded-2xl md:border md:border-[#e5e5e5] md:p-8">
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
      <p className="text-xs text-[#777]">{item.menu.provider_name}</p>
      <h1 className="mt-1 text-xl font-bold">{item.menu.name}</h1>
      <p className="mt-2 text-xs leading-5 text-[#777]">
        {item.menu.description}
      </p>
      <p className="mt-1 font-bold">{money(item.menu.price)}</p>
      {item.menu.fillings.length > 0 && (
        <Choices
          title="Elige tu relleno"
          choices={item.menu.fillings}
          value={filling}
          setValue={setFilling}
        />
      )}
      {item.menu.sauces.length > 0 && (
        <Choices
          title="Elige tu salsa"
          choices={item.menu.sauces}
          value={sauce}
          setValue={setSauce}
        />
      )}
      <section className="border-b border-[#e5e5e5] py-5">
        <div className="flex justify-between text-sm font-medium">
          <h2>Opiniones del plato</h2>
          <span className="text-xs leading-4">
            <Star className="mr-1 inline size-3 fill-black" />
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
              className="flex h-[136px] w-[280px] shrink-0 flex-col gap-3 rounded-md border border-[#e5e5e5] bg-[#f5f5f5] p-4"
            >
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-sm leading-5 font-medium">
                    {index ? "Pedro" : "Lucía"}
                  </span>
                  <span className="text-xs leading-4 text-[#888]">
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
      <section className="border-b border-[#e5e5e5] py-4">
        <label htmlFor="notes" className="text-xs font-semibold">
          Notas para este plato
        </label>
        <Textarea
          id="notes"
          maxLength={140}
          value={notes}
          onChange={(event) => setNotes(event.target.value)}
          placeholder="Escribe las notas que necesites..."
          className="mt-3 h-20 w-full resize-none rounded-lg border-white bg-white p-3 text-xs outline-none placeholder:text-[#999] focus-visible:border-white focus-visible:ring-0 dark:border-white dark:bg-white"
        />
        <p className="text-right text-[10px] text-[#888]">{notes.length}/140</p>
      </section>
      <OrderSummary
        subtotal={subtotal}
        discount={discount}
        total={subtotal - discount}
        percentage={percentage}
      />
      <div className="fixed inset-x-0 bottom-0 flex gap-2 border-t border-[#e5e5e5] bg-white p-6 md:static md:mt-5 md:border-0 md:p-0">
        <QuantityInput
          value={quantity}
          max={item.remaining}
          onChange={setQuantity}
        />
        <Button
          disabled={addDisabled}
          onClick={add}
          className="h-12 flex-1 rounded-lg bg-[#171717] text-white hover:bg-[#171717]/90 disabled:bg-[#999] disabled:text-white disabled:opacity-100"
        >
          Agregar
        </Button>
      </div>
    </div>
  )
}

interface ChoicesProps {
  title: string
  choices: string[]
  value: string
  setValue: (value: string) => void
}

function Choices({ title, choices, value, setValue }: ChoicesProps) {
  return (
    <section className="border-b border-[#e5e5e5] py-5">
      <h2 className="text-xs font-semibold">{title}</h2>
      <RadioGroup
        value={value}
        onValueChange={setValue}
        className="mt-3 space-y-2"
      >
        {choices.map((choice) => (
          <label
            key={choice}
            className="flex cursor-pointer items-center gap-2 text-xs"
          >
            <RadioGroupItem value={choice} aria-label={choice} />
            {choice}
          </label>
        ))}
      </RadioGroup>
    </section>
  )
}
