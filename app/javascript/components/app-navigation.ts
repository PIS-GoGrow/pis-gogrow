import type { TFunction } from "i18next"
import {
  CalendarDays,
  CalendarPlus,
  ClipboardList,
  CreditCard,
  LayoutGrid,
  Package,
  Utensils,
} from "lucide-react"

import {
  adminDashboard,
  consumerAccounts,
  consumerDashboard,
  consumerOrders,
  providerDashboard,
  providerMenus,
  providerOrders,
  schedules,
} from "@/routes"
import type { NavItem, SessionRole } from "@/types"

export type NavigationItem = NavItem & {
  key: string
}

export function getNavigationItems(
  t: TFunction,
): Record<SessionRole, NavigationItem[]> {
  return {
    provider: [
      {
        key: "dashboard",
        title: t("nav.provider.home"),
        href: providerDashboard.index().url,
        icon: LayoutGrid,
      },
      {
        key: "dishes",
        title: t("nav.provider.dishes"),
        href: providerMenus.index().url,
        icon: Utensils,
      },
      {
        key: "menus",
        title: t("nav.provider.menus"),
        href: schedules.index().url,
        icon: CalendarPlus,
      },
      {
        key: "orders",
        title: t("nav.provider.orders"),
        href: providerOrders.index().url,
        icon: Package,
      },
    ],
    admin: [
      {
        key: "dashboard",
        title: t("nav.dashboard"),
        href: adminDashboard.index().url,
        icon: LayoutGrid,
      },
    ],
    consumer: [
      {
        key: "menu",
        title: t("nav.consumer.menu"),
        href: consumerDashboard.index().url,
        icon: CalendarDays,
      },
      {
        key: "orders",
        title: t("nav.orders"),
        href: consumerOrders.index().url,
        icon: ClipboardList,
      },
      {
        key: "payments",
        title: t("nav.payments"),
        href: consumerAccounts.index().url,
        icon: CreditCard,
      },
    ],
  }
}
