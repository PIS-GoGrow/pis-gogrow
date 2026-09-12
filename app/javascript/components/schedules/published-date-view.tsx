import { Badge } from "@/components/ui/badge"
import { UtensilsCrossed } from "lucide-react"

//schedules a publicar

interface PublishedSchedule {
  id: number
  amount: number
  menu: { id: number; name: string }
}

interface PublishedDayViewProps {
  schedules: PublishedSchedule[]
}

export default function PublishedDayView({
  schedules,
}: PublishedDayViewProps) {
  return (
    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
      {schedules.map((schedule) => (
        <div
          key={schedule.id}
          className="flex items-center gap-3 rounded-xl border p-4"
        >
          <div className="flex size-10 shrink-0 items-center justify-center rounded-md bg-muted">
            <UtensilsCrossed className="size-5 text-muted-foreground" />
          </div>

          <div className="flex-1">
            <Badge
              variant="secondary"
              className="mb-1 bg-green-100 text-green-700"
            >
              Publicado
            </Badge>
            <p className="font-medium">{schedule.menu.name}</p>
          </div>

          <p className="text-sm font-medium text-muted-foreground">
            Stock: {schedule.amount}
          </p>
        </div>
      ))}
    </div>
  )
}