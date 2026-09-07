import { Link } from "@inertiajs/react"
import { Utensils } from "lucide-react"
// import { useTranslation } from "react-i18next"

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
import { menus } from "@/routes"
import type { NavItem } from "@/types"

import AppLogo from "./app-logo"

export function AppSidebar() {
  const mainNavItems: NavItem[] = [
    {
      title: t("nav.dashboard"),
      href: dashboard.index({}).url,
      icon: LayoutGrid,
    },
    {
      title: "Platos",
      href: menus.index().url,
      icon: Utensils,
    },
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
