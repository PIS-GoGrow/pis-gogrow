import { Store } from "lucide-react"
import { useTranslation } from "react-i18next"

import { Badge } from "@/components/ui/badge"
import { toggleFavorite } from "@/lib/favorites"
import { formatMoney } from "@/lib/money"
import { cn } from "@/lib/utils"
import type { ConsumerDashboardIndex } from "@/types"

import FavoriteButton from "./favorite-button"

type Schedule = ConsumerDashboardIndex["schedules"][number]
type Shortcut = ConsumerDashboardIndex["favorites"]["menus"][number]
type Providers = ConsumerDashboardIndex["providers"]

interface Props {
  favorites: ConsumerDashboardIndex["favorites"]
  frequent: ConsumerDashboardIndex["frequent"]
  providers: Providers
  schedules: Schedule[]
  activeProviders: Set<number>
  setActiveProviders: (providers: Set<number>) => void
  openDetail: (item: Schedule) => void
}

export default function FavoritesPanel({
  favorites,
  frequent,
  providers,
  schedules,
  activeProviders,
  setActiveProviders,
  openDetail,
}: Props) {
  const { t } = useTranslation()
  const prefix = "pages.consumer_dashboard.index.favorites"

  const favoriteMenuIds = new Set(favorites.menus.map((menu) => menu.id))
  const favoriteProviderIds = new Set(favorites.provider_ids)
  const frequentMenus = frequent.menus.filter(
    (menu) => !favoriteMenuIds.has(menu.id),
  )
  const frequentProviderIds = frequent.provider_ids.filter(
    (id) => !favoriteProviderIds.has(id),
  )

  if (
    favorites.menus.length +
      favorites.provider_ids.length +
      frequentMenus.length +
      frequentProviderIds.length ===
    0
  ) {
    return null
  }

  const providerName = (id: number) =>
    providers.find((provider) => provider.id === id)?.name ?? ""

  function filterByProvider(id: number) {
    setActiveProviders(
      activeProviders.size === 1 && activeProviders.has(id)
        ? new Set()
        : new Set([id]),
    )
  }

  function renderProvider(id: number, isFavorite: boolean) {
    const name = providerName(id)
    if (!name) return null

    return (
      <li
        key={`provider-${id}`}
        className={cn(
          "border-border bg-card flex items-center gap-1 rounded-full border py-0.5 pr-0.5 pl-3",
          activeProviders.has(id) && "border-primary bg-muted",
        )}
      >
        <button
          type="button"
          aria-label={t(`${prefix}.filter_provider`, { name })}
          onClick={() => filterByProvider(id)}
          className="flex items-center gap-1.5 text-sm"
        >
          <Store aria-hidden="true" className="size-3.5" />
          {name}
        </button>
        <FavoriteButton
          active={isFavorite}
          label={t(`${prefix}.${isFavorite ? "remove" : "add"}`, { name })}
          onToggle={() => toggleFavorite("providers", id, isFavorite)}
        />
      </li>
    )
  }

  function renderMenu(menu: Shortcut, isFavorite: boolean) {
    const schedule = schedules.find(
      (item) => item.menu.saved_menu_id === menu.id,
    )
    const available =
      !!schedule && !schedule.sold_out && !schedule.orders_closed

    return (
      <li
        key={`menu-${menu.id}`}
        className={cn(
          "border-border bg-card flex items-center gap-3 rounded-xl border p-3",
          available ? "cursor-pointer" : "opacity-60",
        )}
        onClick={available ? () => openDetail(schedule) : undefined}
      >
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-1.5">
            <span className="text-muted-foreground text-xs">
              {menu.provider_name}
            </span>
            <Badge variant={isFavorite ? "default" : "secondary"}>
              {t(
                `${prefix}.${isFavorite ? "favorite_badge" : "frequent_badge"}`,
              )}
            </Badge>
            {!available && (
              <span className="text-destructive text-xs">
                {t(`${prefix}.unavailable`)}
              </span>
            )}
          </div>
          <p className="truncate text-sm font-semibold">
            {menu.name}{" "}
            <span className="font-normal">| {formatMoney(menu.price)}</span>
          </p>
        </div>
        <FavoriteButton
          active={isFavorite}
          label={t(`${prefix}.${isFavorite ? "remove" : "add"}`, {
            name: menu.name,
          })}
          onToggle={() => toggleFavorite("menus", menu.id, isFavorite)}
        />
      </li>
    )
  }

  const sections = [
    {
      title: t(`${prefix}.title`),
      providerIds: favorites.provider_ids,
      menus: favorites.menus,
      isFavorite: true,
    },
    {
      title: t(`${prefix}.frequent_title`),
      providerIds: frequentProviderIds,
      menus: frequentMenus,
      isFavorite: false,
    },
  ].filter((section) => section.providerIds.length + section.menus.length > 0)

  return (
    <div className="mt-6 flex flex-col gap-4">
      {sections.map((section) => (
        <section key={section.title}>
          <h2 className="mb-2 text-base font-bold">{section.title}</h2>
          {section.providerIds.length > 0 && (
            <ul className="mb-2 flex flex-wrap gap-2">
              {section.providerIds.map((id) =>
                renderProvider(id, section.isFavorite),
              )}
            </ul>
          )}
          <ul className="flex flex-col gap-2">
            {section.menus.map((menu) => renderMenu(menu, section.isFavorite))}
          </ul>
        </section>
      ))}
    </div>
  )
}
