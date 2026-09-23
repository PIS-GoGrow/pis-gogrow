import { UtensilsCrossed } from "lucide-react"

import { Badge } from "@/components/ui/badge"
import type { Schedule } from "@/types"

interface PublishedDayViewProps {
  schedules: Schedule[]
}

export default function PublishedDayView({ schedules }: PublishedDayViewProps) {
  return (
    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
      {schedules.map((schedule) => (
        <div
          key={schedule.id}
          className="flex items-center gap-3 rounded-xl border p-4"
        >
          <div className="bg-muted flex size-10 shrink-0 items-center justify-center rounded-md">
            <UtensilsCrossed className="text-muted-foreground size-5" />
          </div>

          <div className="flex-1">
            <Badge
              variant="secondary"
              className="mb-1 bg-green-100 text-green-700 dark:bg-green-950 dark:text-green-400"
            >
              Publicado
            </Badge>
            <p className="font-medium">{schedule.menu.name}</p>
          </div>

          <p className="text-muted-foreground text-sm font-medium">
            Stock: {schedule.amount}
          </p>
        </div>
      ))}
    </div>
  )
}