import { Link, usePage } from "@inertiajs/react"
import {
  CalendarDays,
  CalendarPlus,
  ClipboardList,
  CreditCard,
  FileCheck,
  LayoutGrid,
  Package,
  Percent,
  Utensils,
} from "lucide-react"
import { useTranslation } from "react-i18next"

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
  consumerAccounts,
  consumerDashboard,
  consumerOrders,
  providerDashboard,
  providerMenus,
  providerOrders,
  providerPayments,
  schedules,
} from "@/routes"
import type { NavItem } from "@/types"

import AppLogo from "./app-logo"

export function AppSidebar() {
  const { t } = useTranslation()
  const { auth } = usePage().props

  const navItems: Record<string, NavItem[]> = {
    provider: [
      {
        title: t("nav.dashboard"),
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
        title: "Validar pagos",
        href: providerPayments.index().url,
        icon: FileCheck,
      },
    ],
    admin: [
      {
        title: t("nav.dashboard"),
        href: adminDashboard.index().url,
        icon: LayoutGrid,
      },
      {
        title: t("nav.benefit_configurations"),
        href: adminBenefitConfigurations.index().url,
        icon: Percent,
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
      hideOnMobile={role === "consumer"}
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
