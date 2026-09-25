import type { ComponentProps } from "react"

import { cn } from "@/lib/utils"

export function BottomAction({
  children,
  className,
  ...props
}: ComponentProps<"div">) {
  return (
    <div
      className={cn(
        "bg-background border-border fixed inset-x-0 bottom-0 grid gap-2 border-t p-6 md:static md:mt-5 md:border-0 md:p-0",
        className,
      )}
      {...props}
    >
      {children}
    </div>
  )
}

export function MobileCard({
  children,
  className,
  ...props
}: ComponentProps<"div">) {
  return (
    <div
      className={cn(
        "bg-background border-border mx-auto min-h-screen max-w-128 gap-2 rounded-xl p-6 pb-28 md:my-8 md:min-h-0 md:border md:pb-6",
        className,
      )}
      {...props}
    >
      {children}
    </div>
  )
}
