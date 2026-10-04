import { useTranslation } from "react-i18next"

import {
  Field,
  FieldError,
  FieldLabel,
  FieldLegend,
  FieldSet,
} from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group"
import type { ProviderMenusEdit } from "@/types"

export type AgendaMode = "single" | "weekly" | "range"

export interface AgendaDraft {
  mode: AgendaMode
  weekdays: number[]
  date: string
  starts_on: string
  ends_on: string
  amount: string
}

export type AgendaPayload =
  { mode: "none" } | ({ mode: AgendaMode } & Omit<AgendaDraft, "mode">)

const WEEKDAYS = [1, 2, 3, 4, 5]
const MODES: AgendaMode[] = ["single", "weekly", "range"]

export function cwday(isoDate: string) {
  const day = new Date(`${isoDate}T00:00:00Z`).getUTCDay()
  return day === 0 ? 7 : day
}

function nextDateFor(weekday: number, from: string) {
  const date = new Date(`${from}T00:00:00Z`)
  while (cwday(date.toISOString().slice(0, 10)) !== weekday) {
    date.setUTCDate(date.getUTCDate() + 1)
  }
  return date.toISOString().slice(0, 10)
}

export function initialAgenda(
  agenda: ProviderMenusEdit["agenda"],
): AgendaDraft {
  return {
    mode: agenda.mode === "none" ? "single" : agenda.mode,
    weekdays: agenda.weekdays,
    date: agenda.date ?? "",
    starts_on: agenda.starts_on ?? "",
    ends_on: agenda.ends_on ?? "",
    amount: agenda.amount?.toString() ?? "",
  }
}

export function agendaPayload(draft: AgendaDraft): AgendaPayload {
  if (draft.weekdays.length === 0) return { mode: "none" }

  return draft
}

interface MenuAgendaFieldsProps {
  value: AgendaDraft
  onChange: (value: AgendaDraft) => void
  today: string
  maximumPublishDate: string
  error?: string
}

export default function MenuAgendaFields({
  value,
  onChange,
  today,
  maximumPublishDate,
  error,
}: MenuAgendaFieldsProps) {
  const { t } = useTranslation()
  const hasDays = value.weekdays.length > 0

  function changeWeekdays(selected: string[]) {
    const weekdays = selected.map(Number).sort()

    if (value.mode !== "single") {
      onChange({ ...value, weekdays })
      return
    }

    const added = weekdays.find((day) => !value.weekdays.includes(day))
    if (added === undefined) {
      onChange({ ...value, weekdays: [], date: "" })
      return
    }

    onChange({ ...value, weekdays: [added], date: nextDateFor(added, today) })
  }

  function changeMode(mode: AgendaMode) {
    if (mode === "single") {
      const weekday = value.weekdays[0]
      onChange({
        ...value,
        mode,
        weekdays: weekday ? [weekday] : [],
        date: weekday ? nextDateFor(weekday, today) : "",
      })
      return
    }

    onChange({ ...value, mode, starts_on: value.starts_on || today })
  }

  function changeDate(date: string) {
    onChange({ ...value, date, weekdays: date ? [cwday(date)] : [] })
  }

  return (
    <FieldSet className="gap-3">
      <FieldLegend variant="label" className="text-base font-semibold">
        {t("pages.provider_menus.edit.agenda.title")}
      </FieldLegend>

      <ToggleGroup
        type="multiple"
        variant="outline"
        spacing={2}
        aria-label={t("pages.provider_menus.edit.agenda.weekdays_label")}
        value={value.weekdays.map(String)}
        onValueChange={changeWeekdays}
      >
        {WEEKDAYS.map((day) => (
          <ToggleGroupItem
            key={day}
            value={String(day)}
            aria-label={t(
              `pages.provider_menus.edit.agenda.weekday_names.${day}`,
            )}
            className="data-[state=on]:border-primary data-[state=on]:bg-primary/10 size-10"
          >
            {t(`pages.provider_menus.edit.agenda.weekdays.${day}`)}
          </ToggleGroupItem>
        ))}
      </ToggleGroup>

      <RadioGroup
        value={value.mode}
        onValueChange={(mode) => changeMode(mode as AgendaMode)}
        className="gap-2"
      >
        {MODES.map((mode) => (
          <Field key={mode} orientation="horizontal">
            <RadioGroupItem value={mode} id={`agenda-mode-${mode}`} />
            <FieldLabel htmlFor={`agenda-mode-${mode}`} className="font-normal">
              {t(`pages.provider_menus.edit.agenda.modes.${mode}`)}
            </FieldLabel>
          </Field>
        ))}
      </RadioGroup>

      {hasDays && (
        <div className="flex flex-col gap-3">
          {value.mode === "single" ? (
            <Field className="max-w-48">
              <FieldLabel htmlFor="agenda-date">
                {t("pages.provider_menus.edit.agenda.date")}
              </FieldLabel>
              <Input
                id="agenda-date"
                type="date"
                min={today}
                max={maximumPublishDate}
                value={value.date}
                onChange={(e) => changeDate(e.target.value)}
              />
            </Field>
          ) : (
            <Field className="max-w-48">
              <FieldLabel htmlFor="agenda-starts-on">
                {t("pages.provider_menus.edit.agenda.starts_on")}
              </FieldLabel>
              <Input
                id="agenda-starts-on"
                type="date"
                min={today}
                value={value.starts_on}
                onChange={(e) =>
                  onChange({ ...value, starts_on: e.target.value })
                }
              />
            </Field>
          )}

          {value.mode === "range" && (
            <Field className="max-w-48">
              <FieldLabel htmlFor="agenda-ends-on">
                {t("pages.provider_menus.edit.agenda.ends_on")}
              </FieldLabel>
              <Input
                id="agenda-ends-on"
                type="date"
                min={value.starts_on || today}
                value={value.ends_on}
                onChange={(e) =>
                  onChange({ ...value, ends_on: e.target.value })
                }
              />
            </Field>
          )}

          <Field className="max-w-48">
            <FieldLabel htmlFor="agenda-amount">
              {t("pages.provider_menus.edit.agenda.amount")}
            </FieldLabel>
            <Input
              id="agenda-amount"
              type="number"
              min={1}
              step={1}
              value={value.amount}
              onChange={(e) => onChange({ ...value, amount: e.target.value })}
            />
          </Field>
        </div>
      )}

      {error && <FieldError>{error}</FieldError>}
    </FieldSet>
  )
}
