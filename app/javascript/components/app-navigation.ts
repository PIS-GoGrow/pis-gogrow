import type { TFunction } from "i18next"
import {
  CalendarDays,
  CalendarPlus,
  ClipboardList,
  CreditCard,
  FileText,
  LayoutGrid,
  Package,
  Percent,
  Utensils,
  UsersRound,
  Wallet,
} from "lucide-react"

import {
  adminBenefitConfigurations,
  adminConsumers,
  adminDashboard,
  adminInvoices,
  adminPayments,
  consumerAccounts,
  consumerDashboard,
  consumerOrders,
  providerCollections,
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
      {
        key: "collections",
        title: t("nav.collections"),
        href: providerCollections.index().url,
        icon: Wallet,
      },
    ],
    admin: [
      {
        key: "dashboard",
        title: t("nav.dashboard"),
        href: adminDashboard.index().url,
        icon: LayoutGrid,
      },
      {
        key: "benefit_configurations",
        title: t("nav.benefit_configurations"),
        href: adminBenefitConfigurations.index().url,
        icon: Percent,
      },
      {
        key: "consumers",
        title: t("nav.admin.employees"),
        href: adminConsumers.index().url,
        icon: UsersRound,
      },
      {
        key: "invoices",
        title: t("nav.invoices"),
        href: adminInvoices.index().url,
        icon: FileText,
      },
      {
        key: "payments",
        title: t("nav.admin.payments"),
        href: adminPayments.index().url,
        icon: CreditCard,
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
