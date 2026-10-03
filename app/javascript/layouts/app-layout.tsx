import type { ReactNode } from "react"

import AppLayoutTemplate from "@/layouts/app/app-sidebar-layout"
import type { BreadcrumbItem } from "@/types"

interface AppLayoutProps {
  children: ReactNode
  breadcrumbs?: BreadcrumbItem[]
  hideMobileHeader?: boolean
}

export default function AppLayout({
  children,
  breadcrumbs,
  hideMobileHeader,
  ...props
}: AppLayoutProps) {
  return (
    <AppLayoutTemplate
      breadcrumbs={breadcrumbs}
      hideMobileHeader={hideMobileHeader}
      {...props}
    >
      {children}
    </AppLayoutTemplate>
  )
}
