import type { LucideIcon } from "lucide-react"

export interface BreadcrumbItem {
  title: string
  href: string
}

export interface NavItem {
  title: string
  href: string
  icon?: LucideIcon | null
  isActive?: boolean
  disabled?: boolean
}

export interface FlashData {
  alert?: string
  notice?: string
}

export * from "./serializers"
