import {
  CreditCardPosIcon,
  Dish02Icon,
  ShoppingBasket01Icon,
  UserIcon,
} from "@hugeicons/core-free-icons"
import { HugeiconsIcon } from "@hugeicons/react"
import { Link, usePage } from "@inertiajs/react"

import { cn } from "@/lib/utils"
import {
  consumerAccounts,
  consumerDashboard,
  orders,
  settingsProfiles,
} from "@/routes"

const links = [
  {
    label: "Menú",
    icon: Dish02Icon,
    href: consumerDashboard.index().url,
    activePrefix: consumerDashboard.index().url,
  },
  {
    label: "Pedidos",
    icon: ShoppingBasket01Icon,
    href: orders.index().url,
    activePrefix: orders.index().url,
  },
  {
    label: "Pagos",
    icon: CreditCardPosIcon,
    href: consumerAccounts.index().url,
    activePrefix: consumerAccounts.index().url,
  },
  {
    label: "Cuenta",
    icon: UserIcon,
    href: settingsProfiles.show().url,
    activePrefix: "/settings",
  },
]

export function ConsumerMobileNav() {
  const { url } = usePage()

  return (
    <nav className="fixed bottom-4 left-1/2 z-30 flex h-[60px] w-[354px] max-w-[calc(100vw-2rem)] -translate-x-1/2 items-center justify-center rounded-full border-y border-white bg-white/80 p-1 shadow-[0px_0px_24px_rgba(10,10,10,0.1),inset_0px_6px_6px_rgba(255,255,255,0.3)] backdrop-blur-[5px] md:hidden dark:border-white/10 dark:bg-neutral-900/80 dark:shadow-[0px_0px_24px_rgba(0,0,0,0.4),inset_0px_1px_1px_rgba(255,255,255,0.1)]">
      {links.map(({ label, icon, href, activePrefix }) => {
        const isActive = url.startsWith(activePrefix)

        return (
          <Link
            key={label}
            href={href}
            prefetch
            aria-current={isActive ? "page" : undefined}
            className={cn(
              "flex h-[52px] w-[86.5px] flex-1 flex-col items-center justify-center gap-0.5 rounded-full p-1 text-[12px] leading-4 font-medium text-[#0A0A0A] transition-colors dark:text-neutral-100",
              isActive
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
        )
      })}
    </nav>
  )
}
