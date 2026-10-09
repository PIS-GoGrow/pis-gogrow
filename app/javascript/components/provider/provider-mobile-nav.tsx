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

import { cn } from "@/lib/utils"
import {
  providerAccount,
  providerCollections,
  providerDashboard,
  providerOperationalSettings,
  providerOrders,
  schedules,
} from "@/routes"

export function ProviderMobileNav() {
  const { t } = useTranslation()
  const { url, component } = usePage()

  const links = [
    {
      label: t("nav.provider.home"),
      icon: Home01Icon,
      href: providerDashboard.index().url,
      active: url.startsWith(providerDashboard.index().url),
    },
    {
      label: t("nav.provider.menu"),
      icon: Dish02Icon,
      href: schedules.index().url,
      active:
        url.startsWith(schedules.index().url) ||
        component.startsWith("provider/menus/"),
    },
    {
      label: t("nav.provider.orders"),
      icon: ShoppingBasket01Icon,
      href: providerOrders.index().url,
      active: url.startsWith(providerOrders.index().url),
    },
    {
      label: t("nav.provider.payments"),
      icon: CreditCardPosIcon,
      href: providerCollections.index().url,
      active: url.startsWith(providerCollections.index().url),
    },
    {
      label: t("nav.provider.account"),
      icon: UserIcon,
      href: providerAccount().url,
      active:
        url.startsWith(providerAccount().url) ||
        url.startsWith(providerOperationalSettings.show().url),
    },
  ]

  return (
    <nav
      aria-label={t("nav.provider.mobile_navigation")}
      className="bg-background fixed inset-x-0 bottom-0 z-30 flex h-[72px] items-center justify-center px-6 md:hidden"
    >
      {links.map(({ label, icon, href, active }) => (
        <Link
          key={label}
          href={href}
          prefetch
          aria-current={active ? "page" : undefined}
          className={cn(
            "text-foreground flex h-[52px] flex-1 flex-col items-center justify-center gap-0.5 rounded-full p-1 text-[12px] leading-4 font-medium transition-colors",
            active
              ? "bg-[#EDEDED] dark:bg-neutral-800"
              : "hover:bg-[#EDEDED]/50 dark:hover:bg-neutral-800/50",
          )}
        >
          <HugeiconsIcon
            icon={icon}
            size={24}
            strokeWidth={2}
            aria-hidden="true"
          />
          <span>{label}</span>
        </Link>
      ))}
    </nav>
  )
}
