import { Link } from "@inertiajs/react"
import type { ReactNode } from "react"

import { Button } from "@/components/ui/button"
import { cn } from "@/lib/utils"

interface MobileNavItem {
  label: string
  icon: ReactNode
  href?: string
  active?: boolean
}

export default function MobileNav({
  label,
  items,
  pendingTitle,
  className,
}: {
  label: string
  items: MobileNavItem[]
  pendingTitle?: string
  className?: string
}) {
  return (
    <nav
      aria-label={label}
      className={cn(
        "fixed bottom-4 left-1/2 z-30 flex h-[60px] w-[354px] max-w-[calc(100vw-2rem)] -translate-x-1/2 items-center justify-center rounded-full border-y border-white bg-white/80 p-1 shadow-[0px_0px_24px_rgba(10,10,10,0.1),inset_0px_6px_6px_rgba(255,255,255,0.3)] backdrop-blur-[5px] md:hidden dark:border-white/10 dark:bg-neutral-900/80 dark:shadow-[0px_0px_24px_rgba(0,0,0,0.4),inset_0px_1px_1px_rgba(255,255,255,0.1)]",
        className,
      )}
    >
      {items.map(({ label: itemLabel, icon, href, active }) => {
        const className = cn(
          "flex h-[52px] w-[86.5px] flex-1 flex-col items-center justify-center gap-0.5 rounded-full p-1 text-[12px] leading-4 font-medium text-[#0A0A0A] transition-colors dark:text-neutral-100",
          active
            ? "bg-[#E5E5E5] dark:bg-neutral-800"
            : "hover:bg-[#E5E5E5]/50 dark:hover:bg-neutral-800/50",
        )
        const content = (
          <>
            {icon}
            <span>{itemLabel}</span>
          </>
        )

        return href ? (
          <Link
            key={itemLabel}
            href={href}
            prefetch
            aria-current={active ? "page" : undefined}
            className={className}
          >
            {content}
          </Link>
        ) : (
          <Button
            key={itemLabel}
            type="button"
            variant="ghost"
            disabled
            aria-disabled="true"
            title={pendingTitle}
            className={cn(
              className,
              "cursor-default disabled:opacity-100 has-[>svg]:px-1",
            )}
          >
            {content}
          </Button>
        )
      })}
    </nav>
  )
}
