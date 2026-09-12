import { router } from "@inertiajs/react"
import { ChevronLeft, ChevronRight } from "lucide-react"

import { Button } from "@/components/ui/button"
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group"
import { cn } from "@/lib/utils"
import { schedules as schedulesRoutes } from "@/routes"

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
function toLocalDate(isoDate: string) {
  return new Date(`${isoDate}T00:00:00`)
}

function weekdayLabel(isoDate: string) {
  return new Intl.DateTimeFormat("es-UY", { weekday: "short" }).format(
    toLocalDate(isoDate),
  )
}

function dayNumberLabel(isoDate: string) {
  return new Intl.DateTimeFormat("es-UY", { day: "numeric" }).format(
    toLocalDate(isoDate),
  )
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
        value={selectedDate ?? ""}
        onValueChange={(value) => value && onSelectDate(value)}
        className="flex-1 justify-between gap-2"
      >
        {days.map((day) => (
          <ToggleGroupItem
            key={day.date}
            value={day.date}
            className={cn(
              "relative flex flex-1 h-[72px] flex-col items-center justify-center gap-0.5 rounded-xl border data-[state=on]:bg-primary data-[state=on]:text-primary-foreground",
              !day.publishable && "text-muted-foreground",
            )}
          >
            <div className="flex flex-col items-center leading-tight">
              <span className="text-xs uppercase">{weekdayLabel(day.date)}</span>
              <span className="text-lg font-semibold">
                {dayNumberLabel(day.date)}
              </span>
            </div>
            
            {day.published && (
              <span className="text-[10px] font-medium text-green-600 data-[state=on]:text-green-400">
                Publicado
              </span>
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
