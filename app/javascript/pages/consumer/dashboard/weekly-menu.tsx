import { UtensilsCrossed } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import { ConsumerMobileNav } from "@/components/consumer/consumer-mobile-nav"
import ClosureBanner from "@/components/consumer/menus/closure-banner"
import MenuItem from "@/components/consumer/menus/menu-item"
import WeekNav from "@/components/consumer/menus/week-nav"
import { ProviderFilterSheet } from "@/components/consumer/provider-filter-sheet"
import NotificationBanners from "@/components/notification-banners"
import { Button } from "@/components/ui/button"
import {
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyMedia,
  EmptyTitle,
} from "@/components/ui/empty"
import useSessionStorage from "@/hooks/use-session-storage"
import type { ConsumerClosure, ConsumerDashboardIndex } from "@/types"

import { BenefitCard } from "./benefit-card"
import type { CartItem, Schedule } from "./consumer-types"
import { money } from "./formatters"

interface Props {
  name: string
  date: string
  setDate: (value: string) => void
  benefit: ConsumerDashboardIndex["benefit"]
  providers: string[]
  schedules: Schedule[]
  closures: ConsumerClosure[]
  cart: CartItem[]
  count: number
  total: number
  openDetail: (item: Schedule) => void
  openCart: () => void
}

export const today = () => {
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
  closures,
  cart,
  count,
  total,
  openDetail,
  openCart,
}: Props) {
  const { t } = useTranslation()
  const [activeProviders, setActiveProviders] = useState<Set<string>>(new Set())
  // Se guarda en la sesión para que el aviso no vuelva al entrar a un plato y
  // volver al menú. Cada aviso (el de antes del cierre y el de durante) se
  // cierra por separado: la clave lleva el tipo y el id del cierre.
  const [dismissed, setDismissed] = useSessionStorage<string[]>(
    "dismissed-closure-notices",
    [],
  )
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
  const soonClosures = closures.filter(
    (closure) =>
      closure.starts_on > date && !dismissed.includes(`soon-${closure.id}`),
  )
  const closedToday = closures.filter(
    (closure) =>
      closure.starts_on <= date &&
      date <= closure.ends_on &&
      (activeProviders.size === 0 ||
        activeProviders.has(closure.provider_name)),
  )
  const closedBanners = closedToday.filter(
    (closure) => !dismissed.includes(`now-${closure.id}`),
  )
  const dismiss = (key: string) => setDismissed((keys) => [...keys, key])

  return (
    <>
      <div className="mx-auto w-full max-w-300 px-5 pt-6 pb-40 md:px-8 md:pb-24 lg:pb-10">
        <header className="mb-4">
          <h1 className="text-2xl font-bold">Hola, {name} 👋</h1>
          <p className="text-muted-foreground text-sm capitalize">
            {new Date(`${currentDate}T00:00:00`).toLocaleDateString("es-UY", {
              weekday: "long",
              day: "numeric",
              month: "long",
            })}
          </p>
        </header>

        <div className="mb-6 flex flex-col gap-3">
          <NotificationBanners />
          {soonClosures.map((closure) => (
            <ClosureBanner
              key={closure.id}
              closure={closure}
              when="soon"
              onDismiss={() => dismiss(`soon-${closure.id}`)}
            />
          ))}
        </div>

        <div className="lg:grid lg:grid-cols-[minmax(0,1fr)_330px] lg:gap-8">
          <section className="min-w-0">
            <BenefitCard benefit={benefit} mobile />

            <h2 className="mt-6 mb-3 text-base font-bold">Menú semanal</h2>
            <WeekNav date={date} onChange={setDate} showArrows={false} />

            {closedBanners.length > 0 && (
              <div className="mt-4 flex flex-col gap-3">
                {closedBanners.map((closure) => (
                  <ClosureBanner
                    key={closure.id}
                    closure={closure}
                    when="now"
                    onDismiss={() => dismiss(`now-${closure.id}`)}
                  />
                ))}
              </div>
            )}

            <div className="mt-6 mb-3 flex items-center">
              <span className="text-foreground min-w-0 truncate text-sm font-medium">
                Proveedores:{" "}
                <span className="text-muted-foreground font-normal">
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
                    {activeProviders.size > 0 && closedToday.length > 0
                      ? closedToday
                          .map((closure) =>
                            t("pages.consumer_dashboard.index.closure.empty", {
                              provider: closure.provider_name,
                              period: closure.period,
                            }),
                          )
                          .join(" ")
                      : schedules.length === 0
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
                      ordersClosed={item.orders_closed}
                      isPast={item.date < currentDate}
                      addedQuantity={addedQuantity || undefined}
                      onSelect={() => openDetail(item)}
                    />
                  )
                })}
              </div>
            )}
          </section>

          <aside className="hidden space-y-4 lg:block">
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

      <style>{`
        @media (min-width: 768px) and (max-width: 1023px) {
          [data-slot="sidebar"][data-state="expanded"] ~ [data-slot="sidebar-inset"] [data-slot="floating-cart-button"] {
            left: calc(var(--sidebar-width) + 2rem);
            right: 2.5rem;
          }

          [data-slot="sidebar"][data-state="collapsed"] ~ [data-slot="sidebar-inset"] [data-slot="floating-cart-button"] {
            left: calc(var(--sidebar-width-icon) + 3.5rem);
            right: 2.5rem;
          }
        }
      `}</style>

      {count > 0 && (
        <Button
          type="button"
          onClick={openCart}
          data-slot="floating-cart-button"
          className="bg-primary text-primary-foreground hover:bg-primary/90 hover:text-primary-foreground fixed right-5 bottom-24 left-5 z-20 h-12 rounded-lg text-sm shadow-lg md:bottom-6 lg:hidden"
        >
          Ver carrito
        </Button>
      )}

      <ConsumerMobileNav />
    </>
  )
}
