import { Link, usePage } from "@inertiajs/react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import type { AgendaPayload } from "@/components/menus/menu-agenda-fields"
import { Button } from "@/components/ui/button"
import {
  Field,
  FieldContent,
  FieldDescription,
  FieldLabel,
  FieldTitle,
} from "@/components/ui/field"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetFooter,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet"
import type { ProviderMenusEdit } from "@/types"

export type EditScope = "day" | "saved"
export type ConfirmedOrders = "keep" | "reject"

type Stage = "scope" | "period" | "orders" | "saved"

interface EditMenuSheetProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  saved: boolean
  processing: boolean
  agenda: AgendaPayload
  today: string
  scheduledDays: ProviderMenusEdit["scheduled_days"]
  returnTo: string
  onApply: (scope: EditScope, confirmedOrders: ConfirmedOrders) => void
}

interface ChoiceProps<T extends string> {
  name: string
  value: T
  onChange: (value: T) => void
  options: { value: T; title: string; description: string }[]
}

function Choice<T extends string>({
  name,
  value,
  onChange,
  options,
}: ChoiceProps<T>) {
  return (
    <RadioGroup
      value={value}
      onValueChange={(selected) => onChange(selected as T)}
      className="gap-3"
    >
      {options.map((option) => (
        <FieldLabel key={option.value} htmlFor={`${name}-${option.value}`}>
          <Field orientation="horizontal">
            <RadioGroupItem
              value={option.value}
              id={`${name}-${option.value}`}
            />
            <FieldContent>
              <FieldTitle>{option.title}</FieldTitle>
              <FieldDescription>{option.description}</FieldDescription>
            </FieldContent>
          </Field>
        </FieldLabel>
      ))}
    </RadioGroup>
  )
}

export default function EditMenuSheet({
  open,
  onOpenChange,
  saved,
  processing,
  agenda,
  today,
  scheduledDays,
  returnTo,
  onApply,
}: EditMenuSheetProps) {
  const { t } = useTranslation()
  const { locale } = usePage().props
  const [scope, setScope] = useState<EditScope>("day")
  const [confirmedOrders, setConfirmedOrders] =
    useState<ConfirmedOrders>("keep")
  const [ordersStep, setOrdersStep] = useState(false)

  const key = "pages.provider_menus.edit.sheet"

  // Mientras el proveedor completa la agenda la fecha puede estar vacía, y
  // Intl.DateTimeFormat tira un RangeError con una fecha inválida.
  const formatDate = (date: string, options: Intl.DateTimeFormatOptions) => {
    const parsed = new Date(`${date}T00:00:00Z`)
    if (!date || Number.isNaN(parsed.getTime())) return ""

    return new Intl.DateTimeFormat(locale, {
      ...options,
      timeZone: "UTC",
    }).format(parsed)
  }

  const formatDayMonth = (date: string) =>
    formatDate(date, { day: "numeric", month: "long" })

  const formatWeekday = (date: string) => formatDate(date, { weekday: "long" })

  function affectedDays(selectedScope: EditScope) {
    switch (agenda.mode) {
      case "single":
        return scheduledDays.filter((day) =>
          selectedScope === "day"
            ? day.date === agenda.date
            : day.date >= agenda.date,
        )
      case "weekly":
        return scheduledDays.filter((day) => day.date >= agenda.starts_on)
      case "range":
        return scheduledDays.filter(
          (day) => day.date >= agenda.starts_on && day.date <= agenda.ends_on,
        )
      default:
        return scheduledDays
    }
  }

  const affected = affectedDays(scope)
  const confirmedCount = affected.reduce(
    (total, day) => total + day.confirmed_orders,
    0,
  )

  const stage: Stage = saved
    ? "saved"
    : agenda.mode === "single"
      ? ordersStep
        ? "orders"
        : "scope"
      : "period"

  function handleOpenChange(next: boolean) {
    onOpenChange(next)

    if (!next) {
      setOrdersStep(false)
      setScope("day")
      setConfirmedOrders("keep")
    }
  }

  function apply() {
    onApply(scope, confirmedCount > 0 ? confirmedOrders : "keep")
  }

  const ordersChoice = (
    <Choice
      name="confirmed-orders"
      value={confirmedOrders}
      onChange={setConfirmedOrders}
      options={(["keep", "reject"] as const).map((value) => ({
        value,
        title: t(`${key}.orders.${value}`),
        description: t(`${key}.orders.${value}_description`),
      }))}
    />
  )

  function periodText() {
    if (agenda.mode === "range") {
      return {
        title: t(`${key}.range.title`),
        description: t(`${key}.range.description`, {
          from: formatDayMonth(agenda.starts_on),
          to: formatDayMonth(agenda.ends_on),
        }),
      }
    }

    if (agenda.mode === "weekly" || affected.length > 0) {
      const from = agenda.mode === "weekly" ? agenda.starts_on : today

      return {
        title: t(`${key}.from.title`),
        description: t(`${key}.from.description`, {
          date: formatDayMonth(from),
        }),
      }
    }

    return {
      title: t(`${key}.simple.title`),
      description: t(`${key}.simple.description`),
    }
  }

  const header = (() => {
    switch (stage) {
      case "saved":
        return {
          title: t(`${key}.saved.title`),
          description: t(`${key}.saved.description`),
        }
      case "scope":
      case "orders":
        return { title: t(`${key}.scope.title`), description: null }
      case "period":
        return periodText()
    }
  })()

  const backButton = (
    <Button
      type="button"
      variant="secondary"
      className="h-11 flex-1"
      disabled={processing}
      onClick={() =>
        stage === "orders" ? setOrdersStep(false) : handleOpenChange(false)
      }
    >
      {t(`${key}.back`)}
    </Button>
  )

  const applyButton = (
    <Button
      type="button"
      className="h-11 flex-1"
      disabled={processing}
      onClick={apply}
    >
      {processing ? t(`${key}.applying`) : t(`${key}.apply`)}
    </Button>
  )

  return (
    <Sheet open={open} onOpenChange={handleOpenChange}>
      <SheetContent
        side="bottom"
        showCloseButton={false}
        className="mx-auto gap-0 rounded-t-3xl pb-[env(safe-area-inset-bottom)] md:max-w-xl"
      >
        <div className="bg-muted-foreground/30 mx-auto mt-3 h-1 w-10 rounded-full" />

        <SheetHeader className="items-start px-6 pt-8 text-left">
          <SheetTitle className="text-base">{header.title}</SheetTitle>
          {header.description ? (
            <SheetDescription className="text-base">
              {header.description}
            </SheetDescription>
          ) : (
            <SheetDescription className="sr-only">
              {header.title}
            </SheetDescription>
          )}
        </SheetHeader>

        {stage === "scope" && agenda.mode === "single" && (
          <div className="px-6 pt-4">
            <Choice
              name="edit-scope"
              value={scope}
              onChange={setScope}
              options={[
                {
                  value: "day",
                  title: t(`${key}.scope.day`),
                  description: t(`${key}.scope.day_description`, {
                    date: `${formatWeekday(agenda.date)} ${formatDayMonth(agenda.date)}`,
                  }),
                },
                {
                  value: "saved",
                  title: t(`${key}.scope.saved`),
                  description: t(`${key}.scope.saved_description`),
                },
              ]}
            />
          </div>
        )}

        {(stage === "orders" || (stage === "period" && confirmedCount > 0)) && (
          <div className="px-6 pt-4">{ordersChoice}</div>
        )}

        <SheetFooter
          className={
            stage === "saved"
              ? "px-6 pt-6 pb-6"
              : "flex-row gap-3 px-6 pt-6 pb-6"
          }
        >
          {stage === "saved" ? (
            <Button type="button" className="h-11 w-full" asChild>
              <Link href={returnTo}>{t(`${key}.done`)}</Link>
            </Button>
          ) : stage === "scope" && confirmedCount > 0 ? (
            <>
              {backButton}
              <Button
                type="button"
                className="h-11 flex-1"
                onClick={() => setOrdersStep(true)}
              >
                {t(`${key}.continue`)}
              </Button>
            </>
          ) : (
            <>
              {backButton}
              {applyButton}
            </>
          )}
        </SheetFooter>
      </SheetContent>
    </Sheet>
  )
}
