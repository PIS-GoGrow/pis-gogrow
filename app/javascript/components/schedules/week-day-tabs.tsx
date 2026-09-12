import { router } from "@inertiajs/react"
import { ChevronLeft, ChevronRight } from "lucide-react"

import { Button } from "@/components/ui/button"
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group"
import { cn } from "@/lib/utils"
import { schedules as schedulesRoutes } from "@/routes"

//como se muestran los dias de la semana

interface Day {
  date: string
  publishable: boolean
  published: boolean
}

interface WeekDayTabsProps {
  days: Day[]
  selectedDate: string | undefined
  onSelectDate: (date: string) => void
  previousWeekStart: string | null
  nextWeekStart: string | null
}

// Rails manda fechas "YYYY-MM-DD". Sin la hora, `new Date(...)` las interpreta
// en UTC, y en un huso horario negativo (como el nuestro) el día mostrado
// puede quedar corrido un día para atrás. Forzamos hora local con "T00:00:00".
function dayLabel(isoDate: string) {
  const date = new Date(`${isoDate}T00:00:00`)
  return new Intl.DateTimeFormat("es-UY", {
    weekday: "short",
    day: "numeric",
  }).format(date)
}

export default function WeekDayTabs({
  days,
  selectedDate,
  onSelectDate,
  previousWeekStart,
  nextWeekStart,
}: WeekDayTabsProps) {
  function goToWeek(weekStart: string | null) {
    if (!weekStart) return

    router.get(
      schedulesRoutes.index().url,
      { week_start: weekStart },
      { preserveState: true },
    )
  }

  return (
    <div className="flex items-center gap-2">
      <Button
        variant="outline"
        size="icon"
        disabled={!previousWeekStart}
        onClick={() => goToWeek(previousWeekStart)}
      >
        <ChevronLeft className="size-4" />
      </Button>

      <ToggleGroup
        type="single"
        variant="outline"
        value={selectedDate ?? ""}
        onValueChange={(value) => value && onSelectDate(value)}
        className="flex-1"
      >
        {days.map((day) => (
          <ToggleGroupItem
            key={day.date}
            value={day.date}
            className={cn(
              "relative flex-col gap-0.5 capitalize",
              !day.publishable && "text-muted-foreground",
            )}
          >
            {dayLabel(day.date)}
            {day.published && (
              <span className="absolute top-1 right-1 size-1.5 rounded-full bg-green-600" />
            )}
          </ToggleGroupItem>
        ))}
      </ToggleGroup>

      <Button
        variant="outline"
        size="icon"
        disabled={!nextWeekStart}
        onClick={() => goToWeek(nextWeekStart)}
      >
        <ChevronRight className="size-4" />
      </Button>
    </div>
  )
}