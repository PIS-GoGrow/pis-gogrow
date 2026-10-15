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
  providerDeliveries,
  providerOperationalSettings,
  providerOrders,
  providerPaymentDetails,
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
        url.startsWith("/provider/menus") ||
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
        url.startsWith(providerOperationalSettings.show().url) ||
        url.startsWith(providerDeliveries.show().url) ||
        url.startsWith(providerPaymentDetails.show().url),
    },
  ]

  return (
    <nav
      aria-label={t("nav.provider.mobile_navigation")}
      className="fixed bottom-4 left-1/2 z-30 flex h-[60px] w-[354px] max-w-[calc(100vw-2rem)] -translate-x-1/2 items-center justify-center rounded-full border-y border-white bg-white/80 p-1 shadow-[0px_0px_24px_rgba(10,10,10,0.1),inset_0px_6px_6px_rgba(255,255,255,0.3)] backdrop-blur-[5px] md:hidden dark:border-white/10 dark:bg-neutral-900/80 dark:shadow-[0px_0px_24px_rgba(0,0,0,0.4),inset_0px_1px_1px_rgba(255,255,255,0.1)]"
    >
      {links.map(({ label, icon, href, active }) => (
        <Link
          key={label}
          href={href}
          prefetch
          aria-current={active ? "page" : undefined}
          className={cn(
            "flex h-[52px] flex-1 flex-col items-center justify-center gap-0.5 rounded-full p-1 text-[12px] leading-4 font-medium text-[#0A0A0A] transition-colors dark:text-neutral-100",
            active
              ? "bg-[#E5E5E5] dark:bg-neutral-800"
              : "hover:bg-[#E5E5E5]/50 dark:hover:bg-neutral-800/50",
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
