import { Form, router } from "@inertiajs/react"
import { CalendarCog, Pencil, Trash2 } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import {
  AdaptableDialog,
  AdaptableDialogContent,
  AdaptableDialogDescription,
  AdaptableDialogFooter,
  AdaptableDialogHeader,
  AdaptableDialogTitle,
} from "@/components/adaptable-dialog"
import { DateRangePicker } from "@/components/date-picker"
import { Button } from "@/components/ui/button"
import { Field, FieldError, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { providerClosures } from "@/routes"
import type { ProviderClosure } from "@/types/serializers/ProviderClosure"

interface ClosuresSectionProps {
  closures: ProviderClosure[]
  today: string
  onboarding?: boolean
}

interface Range {
  from: string
  to: string
}

const page = "pages.provider_operational_settings.show.closures"

export default function ClosuresSection({
  closures,
  today,
  onboarding = false,
}: ClosuresSectionProps) {
  const { t } = useTranslation()
  const [open, setOpen] = useState(false)
  const [stage, setStage] = useState<"form" | "saved">("form")
  const [editing, setEditing] = useState<ProviderClosure | null>(null)
  const [range, setRange] = useState<Range>({ from: "", to: "" })
  const [saved, setSaved] = useState<Range>({ from: "", to: "" })
  const [deletingId, setDeletingId] = useState<number | null>(null)

  // Un solo día se elige con un solo toque: el fin es el mismo día.
  const endsOn = range.to || range.from
  const savedPeriod = closures.find(
    (closure) =>
      closure.starts_on === saved.from && closure.ends_on === saved.to,
  )?.period

  const openAdaptableDialog = (closure: ProviderClosure | null) => {
    setEditing(closure)
    setRange({ from: closure?.starts_on ?? "", to: closure?.ends_on ?? "" })
    setStage("form")
    setOpen(true)
  }

  const handleDelete = (closure: ProviderClosure) => {
    const url = providerClosures.destroy(closure.id).url
    router.delete(onboarding ? `${url}?onboarding=true` : url, {
      preserveScroll: true,
      onStart: () => setDeletingId(closure.id),
      onFinish: () => setDeletingId(null),
    })
  }

  return (
    <>
      <section className="rounded-xl border p-4">
        <div className="mb-4 flex items-start gap-3">
          <CalendarCog className="mt-0.5 size-5 shrink-0" aria-hidden="true" />
          <div>
            <h3 className="text-base font-semibold">{t(`${page}.title`)}</h3>
            <p className="text-muted-foreground text-sm">
              {t(`${page}.description`)}
            </p>
          </div>
        </div>

        {closures.length > 0 && (
          <ul className="mb-3 flex flex-col gap-2">
            {closures.map((closure) => (
              <li
                key={closure.id}
                className="bg-muted/50 flex items-center gap-2 rounded-lg border p-3"
              >
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-semibold">
                    {closure.reason}
                  </p>
                  <p className="text-muted-foreground text-sm">
                    {closure.period}
                  </p>
                </div>
                <Button
                  type="button"
                  variant="ghost"
                  size="icon-sm"
                  disabled={deletingId !== null}
                  aria-label={t(`${page}.edit`, { reason: closure.reason })}
                  onClick={() => openAdaptableDialog(closure)}
                >
                  <Pencil aria-hidden="true" />
                </Button>
                <Button
                  type="button"
                  variant="ghost"
                  size="icon-sm"
                  disabled={deletingId !== null}
                  aria-label={t(`${page}.delete`, { reason: closure.reason })}
                  onClick={() => handleDelete(closure)}
                >
                  <Trash2 aria-hidden="true" />
                </Button>
              </li>
            ))}
          </ul>
        )}

        <Button
          type="button"
          className="h-11 w-full"
          onClick={() => openAdaptableDialog(null)}
        >
          {t(`${page}.schedule`)}
        </Button>
      </section>

      <AdaptableDialog open={open} onOpenChange={setOpen}>
        <AdaptableDialogContent showCloseButton={false} className="p-0">
          {stage === "form" ? (
            <Form
              key={editing?.id ?? "new"}
              method={editing ? "patch" : "post"}
              action={
                editing
                  ? providerClosures.update(editing.id).url
                  : providerClosures.create().url
              }
              options={{ preserveScroll: true }}
              onSuccess={() => {
                setSaved({ from: range.from, to: endsOn })
                setStage("saved")
              }}
            >
              {({ errors, processing }) => {
                const rangeErrors =
                  errors.starts_on ?? errors.ends_on ?? errors.base

                return (
                  <>
                    <AdaptableDialogHeader className="px-6 pt-6 pb-4">
                      <AdaptableDialogTitle className="text-xl">
                        {t(`${page}.${editing ? "edit_title" : "sheet_title"}`)}
                      </AdaptableDialogTitle>
                      <AdaptableDialogDescription>
                        {t(`${page}.sheet_description`)}
                      </AdaptableDialogDescription>
                    </AdaptableDialogHeader>
                    <div className="flex flex-col gap-4 px-6 pb-6">
                      {onboarding && (
                        <input type="hidden" name="onboarding" value="true" />
                      )}
                      <input
                        type="hidden"
                        name="starts_on"
                        value={range.from}
                      />
                      <input type="hidden" name="ends_on" value={endsOn} />
                      <Field>
                        <FieldLabel htmlFor="closure-range">
                          {t(`${page}.date_range`)}
                        </FieldLabel>
                        <DateRangePicker
                          id="closure-range"
                          from={range.from}
                          to={range.to}
                          min={today}
                          weekdaysOnly
                          className="w-full"
                          onChange={(from, to) => setRange({ from, to })}
                        />
                        <FieldError
                          errors={rangeErrors?.map((message) => ({
                            message,
                          }))}
                        />
                      </Field>
                      <Field>
                        <FieldLabel htmlFor="closure-reason">
                          {t(`${page}.reason`)}
                        </FieldLabel>
                        <Input
                          id="closure-reason"
                          name="reason"
                          defaultValue={editing?.reason}
                          placeholder={t(`${page}.reason_placeholder`)}
                          aria-invalid={!!errors.reason}
                        />
                        <FieldError
                          errors={errors.reason?.map((message) => ({
                            message,
                          }))}
                        />
                      </Field>
                    </div>
                    <AdaptableDialogFooter className="flex-row gap-3 px-6 pb-6">
                      <Button
                        type="button"
                        variant="secondary"
                        className="h-11 flex-1"
                        onClick={() => setOpen(false)}
                      >
                        {t(`${page}.cancel`)}
                      </Button>
                      <Button
                        type="submit"
                        className="h-11 flex-1"
                        disabled={processing}
                      >
                        {t(`${page}.save`)}
                      </Button>
                    </AdaptableDialogFooter>
                  </>
                )
              }}
            </Form>
          ) : (
            <>
              <AdaptableDialogHeader className="items-start px-6 pt-8 text-left">
                <AdaptableDialogTitle className="text-base">
                  {t(`${page}.${editing ? "updated_title" : "saved_title"}`)}
                </AdaptableDialogTitle>
                <AdaptableDialogDescription>
                  {t(`${page}.saved_description`, { period: savedPeriod })}
                </AdaptableDialogDescription>
              </AdaptableDialogHeader>
              <AdaptableDialogFooter className="px-6 pt-6 pb-6">
                <Button
                  type="button"
                  className="h-11 w-full"
                  onClick={() => setOpen(false)}
                >
                  {t("pages.provider_operational_settings.show.done")}
                </Button>
              </AdaptableDialogFooter>
            </>
          )}
        </AdaptableDialogContent>
      </AdaptableDialog>
    </>
  )
}
