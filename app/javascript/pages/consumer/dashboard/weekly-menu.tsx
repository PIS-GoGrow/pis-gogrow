import { Settings2 } from "lucide-react"

import { Button } from "@/components/ui/button"
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group"
import { cn } from "@/lib/utils"
import type { ConsumerDashboardIndex } from "@/types"

import { BenefitCard } from "./benefit-card"
import { ConsumerMobileNav } from "./consumer-mobile-nav"
import type { CartItem, Schedule } from "./consumer-types"
import { money, weekday } from "./formatters"
import { MenuCard } from "./menu-card"
import { ProviderFilterSheet } from "./provider-filter-sheet"

interface Props {
  name: string
  week: ConsumerDashboardIndex["week"]
  date: string
  setDate: (value: string) => void
  benefit: ConsumerDashboardIndex["benefit"]
  providers: string[]
  provider: string
  setProvider: (value: string) => void
  schedules: Schedule[]
  cart: CartItem[]
  count: number
  total: number
  openDetail: (item: Schedule) => void
  openCart: () => void
}

export function WeeklyMenu({
  name,
  week,
  date,
  setDate,
  benefit,
  providers,
  provider,
  setProvider,
  schedules,
  cart,
  count,
  total,
  openDetail,
  openCart,
}: Props) {
  const dateLabel = new Date(`${date}T12:00:00`).toLocaleDateString("es-UY", {
    weekday: "long",
    day: "numeric",
    month: "long",
  })

  return (
    <>
      <div className="mx-auto max-w-[1240px] px-6 pt-7 pb-36 md:px-10 md:pb-12">
        <header className="mb-4 md:flex md:justify-between md:border-b md:border-[#e5e5e5] md:pb-7">
          <div>
            <p className="hidden text-[#777] capitalize md:block">
              {dateLabel}
            </p>
            <h1 className="text-xl font-bold md:mt-2 md:text-3xl md:font-medium">
              Hola, {name} 👋
            </h1>
            <p className="mt-1 text-[11px] text-[#888] capitalize md:hidden">
              {dateLabel}
            </p>
          </div>
          <Button
            type="button"
            variant="outline"
            size="icon"
            aria-label="Preferencias del menú"
            disabled
            className="hidden size-11 rounded-xl bg-white md:inline-flex"
          >
            <Settings2 aria-hidden="true" className="size-5" />
          </Button>
        </header>
        <div className="md:grid md:grid-cols-[minmax(0,1fr)_330px] md:gap-7">
          <section>
            <BenefitCard benefit={benefit} mobile />
            <div className="mt-4 flex flex-col gap-4 md:mt-2">
              <div className="flex items-end justify-between">
                <div>
                  <p className="hidden text-sm text-[#777] md:block">
                    Elegí tu almuerzo
                  </p>
                  <h2 className="text-base font-bold md:mt-2 md:text-2xl md:font-medium">
                    Menú semanal
                  </h2>
                </div>
                <p className="hidden text-sm text-[#888] md:block">
                  Semana del {week.days[0]?.day} al {week.days.at(-1)?.day}
                </p>
              </div>
              <ToggleGroup
                type="single"
                variant="outline"
                value={date}
                onValueChange={(value) => value && setDate(value)}
                className="grid h-[60px] w-full grid-cols-5 gap-3 md:h-auto md:max-w-[560px]"
              >
                {week.days.map((day) => (
                  <ToggleGroupItem
                    key={day.date}
                    value={day.date}
                    aria-label={`${weekday(day.date)} ${day.day}`}
                    className={cn(
                      "flex h-[60px] min-w-0 flex-col items-center justify-center rounded-lg border border-[#e5e5e5] bg-white p-2.5 text-[10px] capitalize md:h-16 md:w-auto md:text-sm",
                      date === day.date &&
                        "border-black bg-black font-semibold text-white",
                    )}
                  >
                    <span>{weekday(day.date)}</span>
                    <b className="text-xs md:text-base">{day.day}</b>
                  </ToggleGroupItem>
                ))}
              </ToggleGroup>
              <div className="flex flex-col gap-3">
                <div className="flex h-9 items-center justify-between md:rounded-xl md:bg-[#f2f2f1] md:p-1">
                  <span className="text-[11px] text-[#555] md:hidden">
                    Proveedores: {provider === "all" ? "Todos" : provider}
                  </span>
                  <ProviderFilterSheet
                    providers={providers}
                    provider={provider}
                    setProvider={setProvider}
                  />
                  <ToggleGroup
                    type="single"
                    value={provider}
                    onValueChange={(value) => value && setProvider(value)}
                    className="hidden w-full grid-cols-3 md:grid"
                  >
                    {["all", ...providers].map((providerName) => (
                      <ToggleGroupItem
                        key={providerName}
                        value={providerName}
                        className={cn(
                          "rounded-lg py-2 text-sm",
                          provider === providerName && "bg-white shadow-sm",
                        )}
                      >
                        {providerName === "all" ? "Todos" : providerName}
                      </ToggleGroupItem>
                    ))}
                  </ToggleGroup>
                </div>
                <div className="grid gap-3 md:mt-1 md:grid-cols-2">
                  {schedules.map((item) => (
                    <MenuCard
                      key={item.id}
                      item={item}
                      added={cart.find((cartItem) => cartItem.id === item.id)}
                      openDetail={openDetail}
                    />
                  ))}
                  {!schedules.length && (
                    <p className="col-span-full rounded-xl border border-dashed p-8 text-center text-sm text-[#777]">
                      No hay platos disponibles para este día.
                    </p>
                  )}
                </div>
              </div>
            </div>
          </section>
          <aside className="hidden space-y-4 md:block">
            <BenefitCard benefit={benefit} />
            <div className="rounded-2xl border border-[#e5e5e5] bg-white p-5 shadow-sm">
              <p className="text-sm text-[#888]">Tu carrito</p>
              <h3 className="mt-8 text-lg">
                {count} platos · {money(total)}
              </h3>
              <p className="mt-4 text-sm text-[#888]">
                Agregá platos de distintos días y proveedores.
              </p>
              <Button
                onClick={openCart}
                className="mt-8 w-full bg-black text-white hover:bg-black/85 hover:text-white"
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
          className="fixed inset-x-6 bottom-[92px] z-20 h-12 rounded-lg bg-black text-sm text-white md:hidden"
        >
          Ver carrito
        </Button>
      )}
      <ConsumerMobileNav />
    </>
  )
}
