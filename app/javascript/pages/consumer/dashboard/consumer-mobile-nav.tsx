import { CreditCard, ShoppingBasket, UserRound, Utensils } from "lucide-react"

import { Button } from "@/components/ui/button"
import { cn } from "@/lib/utils"

const links = [
  { label: "Menú", icon: Utensils },
  { label: "Pedidos", icon: ShoppingBasket },
  { label: "Pagos", icon: CreditCard },
  { label: "Cuenta", icon: UserRound },
]

export function ConsumerMobileNav() {
  return (
    <nav className="fixed inset-x-6 bottom-4 z-30 flex h-[60px] items-center justify-around rounded-full border border-[#e5e5e5] bg-white/95 p-1 shadow-lg md:hidden">
      {links.map(({ label, icon: Icon }, index) => (
        <Button
          type="button"
          variant="ghost"
          size="sm"
          key={label}
          disabled={index > 0}
          className={cn(
            "h-[52px] min-w-0 flex-1 flex-col items-center gap-0.5 rounded-full p-1 text-xs leading-4 font-medium text-[#0a0a0a] disabled:opacity-100",
            index === 0 && "bg-[#e5e5e5] hover:bg-[#e5e5e5]",
          )}
        >
          <Icon aria-hidden="true" className="size-6" />
          {label}
        </Button>
      ))}
    </nav>
  )
}
