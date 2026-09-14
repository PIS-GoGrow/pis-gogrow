import { ClipboardList, CreditCard, UserRound, Utensils } from "lucide-react"

import { Button } from "@/components/ui/button"
import { cn } from "@/lib/utils"

const links = [
  { label: "Menú", icon: Utensils },
  { label: "Pedidos", icon: ClipboardList },
  { label: "Pagos", icon: CreditCard },
  { label: "Cuenta", icon: UserRound },
]

export function ConsumerMobileNav() {
  return (
    <nav className="fixed inset-x-6 bottom-4 z-30 flex h-16 items-center justify-around rounded-full border border-[#e5e5e5] bg-white/95 p-1 shadow-lg md:hidden">
      {links.map(({ label, icon: Icon }, index) => (
        <Button
          type="button"
          variant="ghost"
          size="sm"
          key={label}
          disabled={index > 0}
          className={cn(
            "h-12 min-w-14 flex-col items-center gap-0 rounded-full text-[9px]",
            index === 0 && "bg-[#f0f0f0]",
            index > 0 && "opacity-60",
          )}
        >
          <Icon aria-hidden="true" className="size-4" />
          {label}
        </Button>
      ))}
    </nav>
  )
}
