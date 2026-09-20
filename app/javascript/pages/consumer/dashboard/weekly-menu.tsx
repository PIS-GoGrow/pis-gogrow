import { UtensilsCrossed } from "lucide-react"
import { useState } from "react"

import MenuItem from "@/components/consumer/menus/menu-item"
import WeekNav from "@/components/consumer/menus/week-nav"
import { Button } from "@/components/ui/button"
import {
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyMedia,
  EmptyTitle,
} from "@/components/ui/empty"
import type { ConsumerDashboardIndex } from "@/types"

import { BenefitCard } from "./benefit-card"
import { ConsumerMobileNav } from "./consumer-mobile-nav"
import type { CartItem, Schedule } from "./consumer-types"
import { money } from "./formatters"
import { ProviderFilterSheet } from "./provider-filter-sheet"

interface Props {
  name: string
  date: string
  setDate: (value: string) => void
  benefit: ConsumerDashboardIndex["benefit"]
  providers: string[]
  schedules: Schedule[]
  cart: CartItem[]
  count: number
  total: number
  openDetail: (item: Schedule) => void
  openCart: () => void
}

const today = () => {
  const date = new Date()
  const offset = date.getTimezoneOffset()

  return new Date(date.getTime() - offset * 60_000).toISOString().slice(0, 10)
}

export function WeeklyMenu({
  name,
  date,
  setDate,
  benefit,
  providers,
  schedules,
  cart,
  count,
  total,
  openDetail,
  openCart,
}: Props) {
  const [activeProviders, setActiveProviders] = useState<Set<string>>(new Set())
  const currentDate = today()
  const filteredSchedules =
    activeProviders.size === 0
      ? schedules
      : schedules.filter((schedule) =>
          activeProviders.has(schedule.menu.provider_name),
        )
  const filterLabel =
    activeProviders.size === 0
      ? "Todos"
      : providers.filter((provider) => activeProviders.has(provider)).join(", ")

  return (
    <>
      <div className="mx-auto w-full max-w-300 px-5 pt-6 pb-40 md:px-8 md:pb-10">
        <header className="mb-6">
          <h1 className="text-2xl font-bold">Hola, {name} 👋</h1>
          <p className="text-muted-foreground text-sm">
            {new Date(`${date}T00:00:00`).toLocaleDateString("es-UY", {
              weekday: "long",
              day: "numeric",
              month: "long",
            })}
          </p>
        </header>

        <div className="md:grid md:grid-cols-[minmax(0,1fr)_330px] md:gap-8">
          <section className="min-w-0">
            <BenefitCard benefit={benefit} mobile />

            <h2 className="mt-6 mb-3 text-base font-bold">Menú semanal</h2>
            <WeekNav date={date} onChange={setDate} showArrows={false} />

            <div className="mt-6 mb-3 flex items-center">
              <span className="text-muted-foreground min-w-0 truncate text-sm">
                Proveedores:{" "}
                <span className="text-foreground font-medium">
                  {filterLabel}
                </span>
              </span>
              <ProviderFilterSheet
                providers={providers}
                selectedProviders={activeProviders}
                onApply={setActiveProviders}
              />
            </div>

            {filteredSchedules.length === 0 ? (
              <Empty className="mt-8">
                <EmptyHeader>
                  <EmptyMedia variant="icon">
                    <UtensilsCrossed aria-hidden="true" />
                  </EmptyMedia>
                  <EmptyTitle>Menú no disponible</EmptyTitle>
                  <EmptyDescription>
                    {schedules.length === 0
                      ? "Todavía no hay viandas publicadas para este día. Volvé a consultar más tarde."
                      : "No hay platos de los proveedores seleccionados para esta fecha. Probá cambiando el filtro."}
                  </EmptyDescription>
                </EmptyHeader>
              </Empty>
            ) : (
              <div>
                {filteredSchedules.map((item) => {
                  const addedQuantity = cart
                    .filter((cartItem) => cartItem.id === item.id)
                    .reduce((sum, cartItem) => sum + cartItem.quantity, 0)

                  return (
                    <MenuItem
                      key={item.id}
                      providerName={item.menu.provider_name}
                      name={item.menu.name}
                      price={item.menu.price}
                      description={item.menu.description}
                      soldOut={item.sold_out}
                      isPast={item.date < currentDate}
                      addedQuantity={addedQuantity || undefined}
                      onSelect={() => openDetail(item)}
                    />
                  )
                })}
              </div>
            )}
          </section>

          <aside className="hidden space-y-4 md:block">
            <BenefitCard benefit={benefit} />
            <div className="border-border bg-card rounded-xl border p-5">
              <p className="text-muted-foreground text-sm">Tu carrito</p>
              <h3 className="mt-8 text-lg">
                {count} platos · {money(total)}
              </h3>
              <p className="text-muted-foreground mt-4 text-sm">
                Agregá platos de distintos días y proveedores.
              </p>
              <Button
                type="button"
                onClick={openCart}
                disabled={count === 0}
                className="bg-primary text-primary-foreground hover:bg-primary/90 hover:text-primary-foreground mt-8 w-full"
              >
                Ver carrito
              </Button>
            </div>
          </aside>
        </div>
      </div>

      {count > 0 && (
        <Button
          type="button"
          onClick={openCart}
          className="bg-primary text-primary-foreground hover:bg-primary/90 hover:text-primary-foreground fixed inset-x-5 bottom-24 z-20 h-12 rounded-lg text-sm shadow-lg md:hidden"
        >
          Ver carrito
        </Button>
      )}

      <ConsumerMobileNav />
    </>
  )
}
