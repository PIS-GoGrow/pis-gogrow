import { ChevronDown } from "lucide-react"
import type { ReactNode } from "react"

import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible"
import { cn } from "@/lib/utils"

interface BenefitUsageCollapsibleCardProps {
  title: string
  children: ReactNode
  defaultOpen?: boolean
  accessory?: ReactNode
  className?: string
  contentClassName?: string
}

export default function BenefitUsageCollapsibleCard({
  title,
  children,
  defaultOpen = false,
  accessory,
  className,
  contentClassName,
}: BenefitUsageCollapsibleCardProps) {
  return (
    <Collapsible defaultOpen={defaultOpen} asChild>
      <Card
        className={cn(
          "bg-muted gap-0 overflow-hidden rounded-lg py-0 shadow-none",
          className,
        )}
      >
        <CardHeader className="p-0">
          <CollapsibleTrigger asChild>
            <Button
              variant="ghost"
              className="group h-auto w-full justify-between rounded-none px-5 py-5 text-left hover:bg-transparent sm:px-6"
            >
              <CardTitle>
                <h3>{title}</h3>
              </CardTitle>
              <span className="flex shrink-0 items-center gap-3">
                {accessory}
                <ChevronDown
                  aria-hidden="true"
                  className="transition-transform group-data-[state=open]:rotate-180"
                />
              </span>
            </Button>
          </CollapsibleTrigger>
        </CardHeader>
        <CollapsibleContent asChild>
          <CardContent
            className={cn("space-y-6 px-5 pb-6 sm:px-6", contentClassName)}
          >
            {children}
          </CardContent>
        </CollapsibleContent>
      </Card>
    </Collapsible>
  )
}
