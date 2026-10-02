import { Link, usePage } from "@inertiajs/react"
import { useTranslation } from "react-i18next"

import {
  SidebarGroup,
  SidebarGroupLabel,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
} from "@/components/ui/sidebar"
import { cn } from "@/lib/utils"
import type { NavItem } from "@/types"

export function NavMain({ items = [] }: { items: NavItem[] }) {
  const { t } = useTranslation()
  const page = usePage()
  return (
    <SidebarGroup className="px-2 py-0">
      <SidebarGroupLabel>{t("nav.platform")}</SidebarGroupLabel>
      <SidebarMenu>
        {items.map((item) => (
          <SidebarMenuItem key={item.title}>
            <SidebarMenuButton
              asChild={!item.disabled}
              aria-disabled={item.disabled}
              className={cn(
                item.disabled &&
                  "aria-disabled:pointer-events-auto aria-disabled:opacity-100",
              )}
              isActive={!item.disabled && page.url.startsWith(item.href)}
              tooltip={{ children: item.title }}
              title={
                item.disabled
                  ? t("pages.admin.dashboard.coming_soon")
                  : undefined
              }
            >
              {item.disabled ? (
                <>
                  {item.icon && <item.icon />}
                  <span>{item.title}</span>
                </>
              ) : (
                <Link href={item.href} prefetch>
                  {item.icon && <item.icon />}
                  <span>{item.title}</span>
                </Link>
              )}
            </SidebarMenuButton>
          </SidebarMenuItem>
        ))}
      </SidebarMenu>
    </SidebarGroup>
  )
}
