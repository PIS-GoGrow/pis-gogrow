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
import { dashboard, menus } from "@/routes"
import type { NavItem } from "@/types"

import AppLogo from "./app-logo"

export function AppSidebar() {
  const { t } = useTranslation()
  const { auth } = usePage().props

  const navItems = {
	provider: [{
		  title: t("nav.dashboard"),
		  href: dashboard.index({ role: "provider" }).url,
		  icon: LayoutGrid,
		},
		{
		  title: "Platos",
		  href: menus.index().url,
		  icon: Utensils,
		},
	],
	admin: [{
		  title: t("nav.dashboard"),
		  href: dashboard.index({ role: "admin" }).url,
		  icon: LayoutGrid,
		},
	],
	consumer: [{
		  title: t("nav.dashboard"),
		  href: dashboard.index({ role: "consumer" }).url,
		  icon: LayoutGrid,
		},
	]
  }

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
		  <NavMain items={navItems[auth.user.role]} />
      </SidebarContent>

      <SidebarFooter>
        <NavUser />
      </SidebarFooter>
    </Sidebar>
  )
}
