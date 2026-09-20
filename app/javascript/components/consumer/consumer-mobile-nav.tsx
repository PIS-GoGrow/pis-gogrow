import {
  CreditCardPosIcon,
  Dish02Icon,
  ShoppingBasket01Icon,
  UserIcon,
} from "@hugeicons/core-free-icons"
import { HugeiconsIcon } from "@hugeicons/react"
import { Link, usePage } from "@inertiajs/react"

import { Button } from "@/components/ui/button"
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
    activePrefix: "/settings/",
  },
]

export function ConsumerMobileNav() {
  const { url } = usePage()

  return (
    <nav className="border-border bg-background/95 fixed inset-x-6 bottom-4 z-30 flex h-[60px] items-center justify-around rounded-full border p-1 shadow-lg md:hidden">
      {links.map(({ label, icon, href, activePrefix }) => {
        const isActive = url.startsWith(activePrefix)

        return (
          <Button
            variant="ghost"
            size="sm"
            key={label}
            asChild
            className={cn(
              "text-foreground h-[52px] min-w-0 flex-1 flex-col items-center gap-0.5 rounded-full p-1 text-xs leading-4 font-medium",
              isActive && "bg-muted hover:bg-muted",
            )}
          >
            <Link
              href={href}
              prefetch
              aria-current={isActive ? "page" : undefined}
            >
              <HugeiconsIcon icon={icon} size={24} aria-hidden="true" />
              {label}
            </Link>
          </Button>
        )
      })}
    </nav>
  )
}
