import { Link, usePage } from "@inertiajs/react"
import { LayoutGrid, Utensils } from "lucide-react"
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
  providerDashboard,
  providerMenus,
} from "@/routes"
import type { NavItem } from "@/types"

import AppLogo from "./app-logo"

export function AppSidebar() {
  const { t } = useTranslation()
  const { auth } = usePage().props

  const navItems = {
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
        title: t("nav.dashboard"),
        href: consumerDashboard.index().url,
        icon: LayoutGrid,
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
              <Link href={navItems[role][0].url} prefetch>
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
