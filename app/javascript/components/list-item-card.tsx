import type { ComponentProps } from "react"

import { Card } from "@/components/ui/card"
import { cn } from "@/lib/utils"

export default function ListItemCard({
  className,
  ...props
}: ComponentProps<typeof Card>) {
  return (
    <Card
      className={cn("gap-4 py-4 [&>[data-slot^=card-]]:px-4", className)}
      {...props}
    />
  )
}
