import { usePage } from "@inertiajs/react"
import type { PropsWithChildren } from "react"

import { AppContent } from "@/components/app-content"
import { AppShell } from "@/components/app-shell"
import { AppSidebar } from "@/components/app-sidebar"
import { AppSidebarHeader } from "@/components/app-sidebar-header"
import { ProviderMobileNav } from "@/components/provider/provider-mobile-nav"
import { cn } from "@/lib/utils"
import type { BreadcrumbItem } from "@/types"

export default function AppSidebarLayout({
  children,
  breadcrumbs = [],
}: PropsWithChildren<{
  breadcrumbs?: BreadcrumbItem[]
}>) {
  const { auth } = usePage().props
  const isProvider = auth.session.role === "provider"

  return (
    <AppShell variant="sidebar">
      <AppSidebar />
      <AppContent
        variant="sidebar"
        className={cn("overflow-x-hidden", isProvider && "pb-24 md:pb-0")}
      >
        <AppSidebarHeader breadcrumbs={breadcrumbs} />
        {children}
      </AppContent>
      {isProvider && <ProviderMobileNav />}
    </AppShell>
  )
}
