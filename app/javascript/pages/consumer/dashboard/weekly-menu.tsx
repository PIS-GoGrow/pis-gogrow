import { UtensilsCrossed } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import { ConsumerMobileNav } from "@/components/consumer/consumer-mobile-nav"
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
import type { ConsumerDashboardIndex } from "@/types"

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
  cart,
  count,
  total,
  openDetail,
  openCart,
}: Props) {
  const { t } = useTranslation()
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
      ? t("pages.consumer_dashboard.weekly_menu.all_providers")
      : providers.filter((provider) => activeProviders.has(provider)).join(", ")

  return (
    <>
      <div className="mx-auto w-full max-w-300 px-5 pt-6 pb-40 md:px-8 md:pb-10">
        <header className="mb-4">
          <h1 className="text-2xl font-bold">
            {t("pages.consumer_dashboard.weekly_menu.greeting", { name })}
          </h1>
          <p className="text-muted-foreground text-base capitalize">
            {new Date(`${currentDate}T00:00:00`).toLocaleDateString("es-UY", {
              weekday: "long",
              day: "numeric",
              month: "long",
            })}
          </p>
        </header>

        <div className="mb-6">
          <NotificationBanners />
        </div>

        <div className="lg:grid lg:grid-cols-[minmax(0,1fr)_330px] lg:gap-8">
          <section className="min-w-0">
            <BenefitCard benefit={benefit} mobile />

            <h2 className="mt-6 mb-3 text-xl font-bold">
              {t("pages.consumer_dashboard.weekly_menu.title")}
            </h2>
            <WeekNav date={date} onChange={setDate} showArrows={false} />

            <div className="mt-6 mb-3 flex items-center">
              <span className="text-muted-foreground min-w-0 truncate text-sm">
                {t("pages.consumer_dashboard.weekly_menu.providers")}{" "}
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
                  <EmptyTitle>
                    {t("pages.consumer_dashboard.weekly_menu.empty_title")}
                  </EmptyTitle>
                  <EmptyDescription>
                    {schedules.length === 0
                      ? t(
                          "pages.consumer_dashboard.weekly_menu.empty_no_schedules",
                        )
                      : t(
                          "pages.consumer_dashboard.weekly_menu.empty_filtered",
                        )}
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
              <p className="text-muted-foreground text-sm">
                {t("pages.consumer_dashboard.weekly_menu.cart_title")}
              </p>
              <h3 className="mt-8 text-lg">
                {t("pages.consumer_dashboard.weekly_menu.cart_summary", {
                  count,
                  total: money(total),
                })}
              </h3>
              <p className="text-muted-foreground mt-4 text-sm">
                {t("pages.consumer_dashboard.weekly_menu.cart_hint")}
              </p>
              <Button
                type="button"
                onClick={openCart}
                disabled={count === 0}
                className="bg-primary text-primary-foreground hover:bg-primary/90 hover:text-primary-foreground mt-8 w-full"
              >
                {t("pages.consumer_dashboard.weekly_menu.view_cart")}
              </Button>
            </div>
          </aside>
        </div>
      </div>

      {count > 0 && (
        <Button
          type="button"
          onClick={openCart}
          className="bg-primary text-primary-foreground hover:bg-primary/90 hover:text-primary-foreground fixed inset-x-5 bottom-24 z-20 h-12 rounded-[10px] text-base font-medium shadow-lg md:hidden"
        >
          {t("pages.consumer_dashboard.weekly_menu.view_cart")}
        </Button>
      )}

      <ConsumerMobileNav />
    </>
  )
}
