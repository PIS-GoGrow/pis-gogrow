import {
  CreditCardPosIcon,
  Dish02Icon,
  Home01Icon,
  ShoppingBasket01Icon,
  UserIcon,
} from "@hugeicons/core-free-icons"
import { HugeiconsIcon } from "@hugeicons/react"
import { Link, usePage } from "@inertiajs/react"
import { useTranslation } from "react-i18next"

import { getNavigationItems } from "@/components/app-navigation"
import { Button } from "@/components/ui/button"
import { cn } from "@/lib/utils"

export function ProviderMobileNav() {
  const { t } = useTranslation()
  const { url } = usePage()
  const providerItems = getNavigationItems(t).provider
  const dashboard = providerItems.find((item) => item.key === "dashboard")
  const menus = providerItems.find((item) => item.key === "menus")
  const orders = providerItems.find((item) => item.key === "orders")

  const links = [
    {
      label: t("nav.provider.home"),
      icon: Home01Icon,
      href: dashboard?.href,
    },
    {
      label: t("nav.provider.menu"),
      icon: Dish02Icon,
      href: menus?.href,
    },
    {
      label: t("nav.provider.orders"),
      icon: ShoppingBasket01Icon,
      href: orders?.href,
    },
    {
      label: t("nav.provider.payments"),
      icon: CreditCardPosIcon,
    },
    {
      label: t("nav.provider.account"),
      icon: UserIcon,
    },
  ]

  return (
    <nav
      aria-label={t("nav.provider.mobile_navigation")}
      className="bg-background fixed inset-x-0 bottom-0 z-30 flex h-[72px] items-center justify-center px-6 md:hidden"
    >
      {links.map(({ label, icon, href }) => {
        const isActive = href !== undefined && url.startsWith(href)
        const className = cn(
          "text-foreground flex h-[52px] flex-1 flex-col items-center justify-center gap-0.5 rounded-full p-1 text-[12px] leading-4 font-medium transition-colors",
          isActive
            ? "bg-[#EDEDED] dark:bg-neutral-800"
            : "hover:bg-[#EDEDED]/50 dark:hover:bg-neutral-800/50",
        )

        if (!href) {
          return (
            <Button
              key={label}
              type="button"
              variant="ghost"
              aria-disabled="true"
              className={cn(className, "cursor-pointer has-[>svg]:px-1")}
            >
              <HugeiconsIcon
                icon={icon}
                size={24}
                strokeWidth={2}
                aria-hidden="true"
              />
              <span>{label}</span>
            </Button>
          )
        }

        return (
          <Link
            key={label}
            href={href}
            prefetch
            aria-current={isActive ? "page" : undefined}
            className={className}
          >
            <HugeiconsIcon
              icon={icon}
              size={24}
              strokeWidth={2}
              aria-hidden="true"
            />
            <span>{label}</span>
          </Link>
        )
      })}
    </nav>
  )
}
