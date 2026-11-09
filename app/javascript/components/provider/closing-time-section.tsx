import { Form, router } from "@inertiajs/react"
import { Clock3 } from "lucide-react"
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
import { Button } from "@/components/ui/button"
import { Field, FieldError, FieldLabel } from "@/components/ui/field"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { providerOrderDeadline } from "@/routes"

const quarterHourOptions = Array.from({ length: 96 }, (_, index) => {
  const hours = String(Math.floor(index / 4)).padStart(2, "0")
  const minutes = String((index % 4) * 15).padStart(2, "0")
  return `${hours}:${minutes}`
})

const page = "pages.provider_operational_settings.show"

interface ClosingTimeSectionProps {
  orderDeadline?: string | null
  orderDeadlinePassedToday: boolean
  onboarding?: boolean
}

export default function ClosingTimeSection({
  orderDeadline,
  orderDeadlinePassedToday,
  onboarding = false,
}: ClosingTimeSectionProps) {
  const { t } = useTranslation()
  const [open, setOpen] = useState(false)
  const [stage, setStage] = useState<"form" | "saved">("form")
  const [newTime, setNewTime] = useState("")
  const [editError, setEditError] = useState<string | undefined>()

  const options =
    orderDeadline && !quarterHourOptions.includes(orderDeadline)
      ? [...quarterHourOptions, orderDeadline].sort()
      : quarterHourOptions

  const close = () => setOpen(false)

  return (
    <>
      <section className="rounded-xl border p-4">
        <div className="mb-4 flex items-start gap-3">
          <Clock3 className="mt-0.5 size-5 shrink-0" aria-hidden="true" />
          <div>
            <h3 className="text-base font-semibold">
              {t(`${page}.closing_time`)}
            </h3>
            <p className="text-muted-foreground text-sm">
              {t(`${page}.closing_time_description`)}
            </p>
          </div>
        </div>

        {orderDeadline ? (
          <div>
            <Select
              value={orderDeadline}
              onValueChange={(value) => {
                setEditError(undefined)
                router.patch(
                  providerOrderDeadline().url,
                  onboarding
                    ? { order_deadline: value, onboarding: true }
                    : { order_deadline: value },
                  {
                    preserveScroll: true,
                    onError: (errors) =>
                      setEditError(errors.order_deadline?.[0]),
                    onSuccess: () => {
                      setNewTime(value)
                      setStage("saved")
                      setOpen(true)
                    },
                  },
                )
              }}
            >
              <SelectTrigger
                className="w-full"
                aria-label={t(`${page}.closing_time`)}
                aria-invalid={!!editError}
              >
                <SelectValue />
              </SelectTrigger>
              <SelectContent className="max-h-48">
                {options.map((time) => (
                  <SelectItem key={time} value={time}>
                    {time}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            {editError && <FieldError>{editError}</FieldError>}
          </div>
        ) : (
          <Button
            type="button"
            className="h-11 w-full"
            onClick={() => {
              setStage("form")
              setNewTime("")
              setOpen(true)
            }}
          >
            {t(`${page}.add_closing_time`)}
          </Button>
        )}
      </section>

      <AdaptableDialog open={open} onOpenChange={(value) => !value && close()}>
        <AdaptableDialogContent showCloseButton={false} className="p-0">
          {stage === "form" ? (
            <Form
              method="patch"
              action={providerOrderDeadline().url}
              options={{ preserveScroll: true }}
              onSuccess={() => setStage("saved")}
            >
              {({ errors, processing }) => (
                <>
                  <AdaptableDialogHeader className="px-6 pt-6 pb-4">
                    <AdaptableDialogTitle className="text-xl">
                      {t(`${page}.add_closing_time_title`)}
                    </AdaptableDialogTitle>
                    <AdaptableDialogDescription className="sr-only">
                      {t(`${page}.closing_time_description`)}
                    </AdaptableDialogDescription>
                  </AdaptableDialogHeader>
                  <div className="px-6 pb-6">
                    {onboarding && (
                      <input type="hidden" name="onboarding" value="true" />
                    )}
                    <Field>
                      <FieldLabel htmlFor="order_deadline">
                        {t(`${page}.closing_time`)}
                      </FieldLabel>
                      <Select
                        name="order_deadline"
                        value={newTime}
                        onValueChange={setNewTime}
                      >
                        <SelectTrigger
                          id="order_deadline"
                          className="w-full"
                          aria-invalid={!!errors.order_deadline}
                        >
                          <SelectValue
                            placeholder={t(`${page}.closing_time_placeholder`)}
                          />
                        </SelectTrigger>
                        <SelectContent className="max-h-48">
                          {quarterHourOptions.map((time) => (
                            <SelectItem key={time} value={time}>
                              {time}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                      <FieldError
                        errors={errors.order_deadline?.map((message) => ({
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
                      onClick={close}
                    >
                      {t("common.cancel")}
                    </Button>
                    <Button
                      type="submit"
                      className="h-11 flex-1"
                      disabled={processing || !newTime}
                    >
                      {t(`${page}.save_changes`)}
                    </Button>
                  </AdaptableDialogFooter>
                </>
              )}
            </Form>
          ) : (
            <>
              <AdaptableDialogHeader className="items-start px-6 pt-8 text-left">
                <AdaptableDialogTitle className="text-base">
                  {t(`${page}.saved_title`)}
                </AdaptableDialogTitle>
                <AdaptableDialogDescription>
                  {t(
                    `${page}.${orderDeadlinePassedToday ? "saved_description_closed_today" : "saved_description"}`,
                    { time: newTime },
                  )}
                </AdaptableDialogDescription>
              </AdaptableDialogHeader>
              <AdaptableDialogFooter className="px-6 pt-6 pb-6">
                <Button type="button" className="h-11 w-full" onClick={close}>
                  {t(`${page}.done`)}
                </Button>
              </AdaptableDialogFooter>
            </>
          )}
        </AdaptableDialogContent>
      </AdaptableDialog>
    </>
  )
}
