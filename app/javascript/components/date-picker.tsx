import { format, parseISO } from "date-fns"
import { ChevronDown } from "lucide-react"
import { useState } from "react"
import type { Matcher } from "react-day-picker"
import { es } from "react-day-picker/locale"
import { useTranslation } from "react-i18next"

import { Button } from "@/components/ui/button"
import { Calendar } from "@/components/ui/calendar"
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover"

const toDate = (iso: string) => (iso ? parseISO(iso) : undefined)
const toIso = (date: Date) => format(date, "yyyy-MM-dd")

const capitalize = (text: string) =>
  text.replace(/(^|\s)\p{L}/gu, (letter) => letter.toUpperCase())

function disabledDays(min?: string, max?: string, weekdaysOnly?: boolean) {
  const matchers: Matcher[] = []
  if (min) matchers.push({ before: parseISO(min) })
  if (max) matchers.push({ after: parseISO(max) })
  if (weekdaysOnly) matchers.push({ dayOfWeek: [0, 6] })
  return matchers
}

interface DatePickerProps {
  id?: string
  value: string
  onChange: (value: string) => void
  min?: string
  max?: string
  weekdaysOnly?: boolean
}

export function DatePicker({
  id,
  value,
  onChange,
  min,
  max,
  weekdaysOnly,
}: DatePickerProps) {
  const { t } = useTranslation()
  const [open, setOpen] = useState(false)
  const selected = toDate(value)

  return (
    <div>
      <Popover open={open} onOpenChange={setOpen}>
        <PopoverTrigger asChild>
          <Button
            id={id}
            type="button"
            variant="outline"
            className="w-fit min-w-44 justify-between font-normal"
          >
            {selected
              ? capitalize(format(selected, "MMMM d, yyyy", { locale: es }))
              : t("components.date_picker.placeholder")}
            <ChevronDown aria-hidden="true" className="text-muted-foreground" />
          </Button>
        </PopoverTrigger>
        <PopoverContent className="w-auto overflow-hidden p-0" align="start">
          <Calendar
            mode="single"
            locale={es}
            captionLayout="dropdown"
            selected={selected}
            defaultMonth={selected ?? toDate(min ?? "")}
            disabled={disabledDays(min, max, weekdaysOnly)}
            onSelect={(date) => {
              onChange(date ? toIso(date) : "")
              setOpen(false)
            }}
          />
        </PopoverContent>
      </Popover>
    </div>
  )
}

interface DateRangePickerProps {
  id?: string
  from: string
  to: string
  onChange: (from: string, to: string) => void
  min?: string
}

export function DateRangePicker({
  id,
  from,
  to,
  onChange,
  min,
}: DateRangePickerProps) {
  const { t } = useTranslation()
  const start = toDate(from)
  const end = toDate(to)
  const label = (date: Date) =>
    capitalize(format(date, "MMM dd, yyyy", { locale: es }))

  return (
    <div>
      <Popover>
        <PopoverTrigger asChild>
          <Button
            id={id}
            type="button"
            variant="outline"
            className="w-fit min-w-44 justify-between font-normal"
          >
            {start
              ? end
                ? `${label(start)} - ${label(end)}`
                : label(start)
              : t("components.date_picker.range_placeholder")}
            <ChevronDown aria-hidden="true" className="text-muted-foreground" />
          </Button>
        </PopoverTrigger>
        <PopoverContent className="w-auto overflow-hidden p-0" align="start">
          <Calendar
            mode="range"
            locale={es}
            captionLayout="dropdown"
            selected={{ from: start, to: end }}
            defaultMonth={start ?? toDate(min ?? "")}
            disabled={disabledDays(min)}
            onSelect={(range) =>
              onChange(
                range?.from ? toIso(range.from) : "",
                range?.to ? toIso(range.to) : "",
              )
            }
          />
        </PopoverContent>
      </Popover>
    </div>
  )
}
