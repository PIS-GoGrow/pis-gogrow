import { router } from "@inertiajs/react"
import { ChevronLeft, ChevronRight } from "lucide-react"
import { useTranslation } from "react-i18next"

import { Button } from "@/components/ui/button"
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group"
import { cn } from "@/lib/utils"
import { schedules as schedulesRoutes } from "@/routes"

interface Day {
  date: string
  publishable: boolean
}

interface WeekDayTabsProps {
  days: Day[]
  selectedDate: string | undefined
  onSelectDate: (date: string) => void
  previousWeekStart: string | null
  nextWeekStart: string | null
  today: string
}

// Rails manda fechas "YYYY-MM-DD". Sin la hora, `new Date(...)` las interpreta
// en UTC, y en un huso horario negativo (como el nuestro) el día mostrado
// puede quedar corrido un día para atrás. Forzamos hora local con "T00:00:00".
function toLocalDate(isoDate: string) {
  return new Date(`${isoDate}T00:00:00`)
}

function capitalize(text: string) {
  return text.charAt(0).toLocaleUpperCase("es-UY") + text.slice(1)
}

function format(isoDate: string, options: Intl.DateTimeFormatOptions) {
  return capitalize(
    new Intl.DateTimeFormat("es-UY", options)
      .format(toLocalDate(isoDate))
      .replace(".", ""),
  )
}

// Qué día queda elegido al abrir una semana: hoy si la semana es la actual y
// hoy es día hábil; en cualquier otro caso (semanas pasadas o futuras, o un fin
// de semana) el lunes.
export function defaultDayOfWeek(weekStart: string, today: string) {
  const end = new Date(`${weekStart}T00:00:00Z`)
  end.setUTCDate(end.getUTCDate() + 4)
  const weekEnd = end.toISOString().slice(0, 10)

  return today >= weekStart && today <= weekEnd ? today : weekStart
}

export default function WeekDayTabs({
  days,
  selectedDate,
  onSelectDate,
  previousWeekStart,
  nextWeekStart,
  today,
}: WeekDayTabsProps) {
  const { t } = useTranslation()
  const first = days[0]?.date
  const last = days[days.length - 1]?.date

  function goToWeek(weekStart: string | null) {
    if (!weekStart) return

    onSelectDate(defaultDayOfWeek(weekStart, today))
    router.get(
      schedulesRoutes.index().url,
      { week_start: weekStart },
      { preserveState: true },
    )
  }

  function dayLabel(isoDate: string) {
    return `${format(isoDate, { weekday: "long" })} ${Number(isoDate.slice(8))}`
  }

  const sameMonth = first?.slice(0, 7) === last?.slice(0, 7)

  return (
    <div className="flex flex-col gap-3">
      <div className="flex items-center justify-between gap-2">
        <Button
          variant="ghost"
          size="icon"
          className="size-6"
          aria-label={t("pages.schedules.index.previous_week")}
          disabled={!previousWeekStart}
          onClick={() => goToWeek(previousWeekStart)}
        >
          <ChevronLeft aria-hidden="true" className="size-4" />
        </Button>

        {first && last && (
          <p className="text-muted-foreground text-sm font-medium">
            {t("pages.schedules.index.week_range", {
              from: sameMonth
                ? dayLabel(first)
                : `${dayLabel(first)} ${format(first, { month: "long" })}`,
              to: dayLabel(last),
              month: `${format(last, { month: "long" })} ${last.slice(0, 4)}`,
            })}
          </p>
        )}

        <Button
          variant="ghost"
          size="icon"
          className="size-6"
          aria-label={t("pages.schedules.index.next_week")}
          disabled={!nextWeekStart}
          onClick={() => goToWeek(nextWeekStart)}
        >
          <ChevronRight aria-hidden="true" className="size-4" />
        </Button>
      </div>

      <ToggleGroup
        type="single"
        value={selectedDate ?? ""}
        onValueChange={(value) => value && onSelectDate(value)}
        spacing={3}
        className="w-full justify-between"
      >
        {days.map((day) => (
          <ToggleGroupItem
            key={day.date}
            value={day.date}
            className={cn(
              "data-[state=on]:bg-primary data-[state=on]:text-primary-foreground flex h-12 flex-1 flex-col items-center justify-center gap-0 rounded-lg border text-sm leading-tight",
              !day.publishable && "text-muted-foreground",
            )}
          >
            <span>{format(day.date, { weekday: "short" })}</span>
            <span>{Number(day.date.slice(8))}</span>
          </ToggleGroupItem>
        ))}
      </ToggleGroup>
    </div>
  )
}
