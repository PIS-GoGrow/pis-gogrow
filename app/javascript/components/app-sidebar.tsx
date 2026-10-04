import { Link, usePage } from "@inertiajs/react"
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
  Wallet,
} from "lucide-react"
import { useTranslation } from "react-i18next"

import { useAdminPrimaryNavItems } from "@/components/admin/admin-nav-items"
import { NavMain } from "@/components/nav-main"
import { NavUser } from "@/components/nav-user"
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
} from "@/components/ui/sidebar"
import {
  adminBenefitConfigurations,
  adminDashboard,
  adminPayments,
  adminInvoices,
  consumerAccounts,
  consumerDashboard,
  consumerOrders,
  providerCollections,
  providerDashboard,
  providerMenus,
  providerOrders,
  schedules,
} from "@/routes"
import type { NavItem } from "@/types"

import AppLogo from "./app-logo"

export function AppSidebar() {
  const { t } = useTranslation()
  const { auth } = usePage().props
  const adminPrimaryNavItems = useAdminPrimaryNavItems()

  const navItems: Record<string, NavItem[]> = {
    provider: [
      {
        title: t("nav.provider.home"),
        href: providerDashboard.index().url,
        icon: LayoutGrid,
      },
      {
        title: "Platos",
        href: providerMenus.index().url,
        icon: Utensils,
      },
      {
        title: "Publicar menús",
        href: schedules.index().url,
        icon: CalendarPlus,
      },
      {
        title: "Pedidos",
        href: providerOrders.index().url,
        icon: Package,
      },
      {
        title: t("nav.collections"),
        href: providerCollections.index().url,
        icon: Wallet,
      },
    ],
    admin: [
      ...adminPrimaryNavItems,
      {
        title: t("nav.benefit_configurations"),
        href: adminBenefitConfigurations.index().url,
        icon: Percent,
      },
      {
        title: t("nav.payments"),
        href: adminPayments.index().url,
        icon: CreditCard,
        title: t("nav.invoices"),
        href: adminInvoices.index().url,
        icon: FileText,
      },
    ],
    consumer: [
      {
        title: "Menú del día",
        href: consumerDashboard.index().url,
        icon: CalendarDays,
      },
      {
        title: t("nav.orders"),
        href: consumerOrders.index().url,
        icon: ClipboardList,
      },
      {
        title: t("nav.payments"),
        href: consumerAccounts.index().url,
        icon: CreditCard,
      },
    ],
  }

  const role = auth.session.role

  return (
    <Sidebar
      collapsible="icon"
      variant="inset"
      hideOnMobile={
        role === "consumer" || role === "provider" || role === "admin"
      }
    >
      <SidebarHeader>
        <SidebarMenu>
          <SidebarMenuItem>
            <SidebarMenuButton size="lg" asChild>
              <Link href={navItems[role][0]?.href} prefetch>
                <AppLogo />
              </Link>
            </SidebarMenuButton>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarHeader>

      <SidebarContent>
        <NavMain items={navItems[role]} />
      </SidebarContent>

      <SidebarFooter>
        <NavUser />
      </SidebarFooter>
    </Sidebar>
  )
}
