import { Link, usePage } from "@inertiajs/react"
import { ClipboardList, LayoutGrid, Utensils } from "lucide-react"
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
import { dashboard, menus, orders } from "@/routes"
import type { NavItem } from "@/types"

import AppLogo from "./app-logo"

export function AppSidebar() {
  const { t } = useTranslation()
  const { auth } = usePage().props

  // La navegación se arma por rol: el cliente pidió que las experiencias de
  // empleado y proveedor nunca se mezclen en pantalla.
  const mainNavItems: NavItem[] = [
    {
      title: t("nav.dashboard"),
      href: dashboard.index({}).url,
      icon: LayoutGrid,
    },
    ...(auth.user?.provider
      ? [
          {
            title: "Platos",
            href: menus.index().url,
            icon: Utensils,
          },
        ]
      : []),
    ...(auth.user?.consumer
      ? [
          {
            title: t("nav.orders"),
            href: orders.index().url,
            icon: ClipboardList,
          },
        ]
      : []),
  ]

  return (
    <Sidebar collapsible="icon" variant="inset">
      <SidebarHeader>
        <SidebarMenu>
          <SidebarMenuItem>
            <SidebarMenuButton size="lg" asChild>
              <Link href={dashboard.index({})} prefetch>
                <AppLogo />
              </Link>
            </SidebarMenuButton>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarHeader>

      <SidebarContent>
        <NavMain items={mainNavItems} />
      </SidebarContent>

      <SidebarFooter>
        <NavUser />
      </SidebarFooter>
    </Sidebar>
  )
}
