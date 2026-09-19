import { Link, usePage } from "@inertiajs/react"
import {
  CalendarDays,
  CalendarPlus,
  ClipboardList,
  LayoutGrid,
  Utensils,
  FileCheck,
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
  adminDashboard,
  consumerDashboard,
  orders,
  providerDashboard,
  providerMenus,
  schedules,
  providerPayments,
  consumerPayments,
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
    ],
    consumer: [
      {
        title: "Menú del día",
        href: consumerDashboard.index().url,
        icon: CalendarDays,
      },
      {
        title: t("nav.orders"),
        href: orders.index().url,
        icon: ClipboardList,
      },
      {
        title: "Mis pagos",
        href: consumerPayments.index().url,
        icon: FileCheck,
      },
    ],
  }

  const role = auth.session.role

  return (
    <Sidebar collapsible="icon" variant="inset">
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
