import { ChevronLeft, ChevronRight } from "lucide-react"

import { Button } from "@/components/ui/button"
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group"

function toLocalDate(isoDate: string) {
  return new Date(`${isoDate}T00:00:00`)
}

function toDateStr(d: Date): string {
  return [
    d.getFullYear(),
    String(d.getMonth() + 1).padStart(2, "0"),
    String(d.getDate()).padStart(2, "0"),
  ].join("-")
}

function getMondayOf(dateStr: string): Date {
  const d = toLocalDate(dateStr)
  const dow = d.getDay()
  d.setDate(d.getDate() - (dow === 0 ? 6 : dow - 1))
  return d
}

function getWeekDays(dateStr: string): string[] {
  const monday = getMondayOf(dateStr)
  return Array.from({ length: 5 }, (_, i) => {
    const d = new Date(monday)
    d.setDate(monday.getDate() + i)
    return toDateStr(d)
  })
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

export default function WeekNav({
  date,
  onChange,
  showArrows = true,
}: {
  date: string
  onChange: (date: string) => void
  showArrows?: boolean
}) {
  const days = getWeekDays(date)

  const monday = getMondayOf(date)

  const prevMonday = new Date(monday)
  prevMonday.setDate(monday.getDate() - 7)

  const nextMonday = new Date(monday)
  nextMonday.setDate(monday.getDate() + 7)

  return (
    <div className="flex items-center gap-2">
      {showArrows && (
        <Button
          variant="outline"
          size="icon"
          aria-label="Semana anterior"
          onClick={() => onChange(toDateStr(prevMonday))}
        >
          <ChevronLeft aria-hidden="true" className="size-4" />
        </Button>
      )}

      <ToggleGroup
        type="single"
        spacing={2}
        value={date}
        onValueChange={(value) => value && onChange(value)}
        className="flex-1 justify-between"
      >
        {days.map((d) => (
          <ToggleGroupItem
            key={d}
            value={d}
            className="flex h-[60px] flex-1 flex-col items-center justify-center gap-0.5 rounded-md border p-2.5 data-[state=on]:bg-black data-[state=on]:text-white data-[state=on]:hover:bg-black"
          >
            <span className="text-sm leading-5 font-bold tracking-normal capitalize">
              {weekdayLabel(d)}
            </span>
            <span className="text-sm leading-5 font-bold tracking-normal">
              {dayNumberLabel(d)}
            </span>
          </ToggleGroupItem>
        ))}
      </ToggleGroup>

      {showArrows && (
        <Button
          variant="outline"
          size="icon"
          aria-label="Semana siguiente"
          onClick={() => onChange(toDateStr(nextMonday))}
        >
          <ChevronRight aria-hidden="true" className="size-4" />
        </Button>
      )}
    </div>
  )
}
