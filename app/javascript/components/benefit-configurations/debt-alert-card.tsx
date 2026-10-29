import { Form } from "@inertiajs/react"
import { PencilIcon } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import { Button } from "@/components/ui/button"
import {
  Field,
  FieldContent,
  FieldError,
  FieldLabel,
} from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { useFormatters } from "@/hooks/use-formatters"
import { adminDebtAlert } from "@/routes"

interface DebtAlertCardProps {
  threshold: number
}

export default function DebtAlertCard({ threshold }: DebtAlertCardProps) {
  const { t } = useTranslation()
  const { formatMoney } = useFormatters()
  const [isEditing, setIsEditing] = useState(false)

  const scope = "pages.admin.benefit_configurations.index.debt_alert"

  return (
    <section className="flex flex-col gap-3">
      <div className="flex flex-col gap-1">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-bold text-foreground">
            {t(`${scope}.title`)}
          </h2>

          {!isEditing && (
            <Button
              variant="ghost"
              size="sm"
              className="gap-1.5 font-semibold text-foreground"
              onClick={() => setIsEditing(true)}
            >
              <PencilIcon className="size-4" />
              {t(`${scope}.edit`)}
            </Button>
          )}
        </div>
        <p className="text-base text-muted-foreground">
          {t(`${scope}.description`)}
        </p>
      </div>

      {isEditing ? (
        <div className="rounded-lg border border-[#E5E5E5] bg-card p-4 dark:border-neutral-800">
          <Form
            action={adminDebtAlert()}
            options={{ preserveScroll: true }}
            onSuccess={() => setIsEditing(false)}
            noValidate
            className="grid gap-4"
          >
            {({ errors, processing }) => (
              <>
                <Field
                  orientation="horizontal"
                  data-invalid={!!errors.debt_alert_threshold}
                >
                  <FieldLabel
                    htmlFor="debt_alert_threshold"
                    className="font-normal"
                  >
                    {t(`${scope}.threshold`)}
                  </FieldLabel>
                  <FieldContent className="flex-none">
                    <div className="flex items-center gap-2">
                      <span className="text-muted-foreground">$</span>
                      <Input
                        id="debt_alert_threshold"
                        name="company[debt_alert_threshold]"
                        type="number"
                        min="1"
                        max="1000000"
                        step="1"
                        className="w-32 text-base"
                        defaultValue={threshold}
                        aria-invalid={!!errors.debt_alert_threshold}
                      />
                    </div>
                    <FieldError>{errors.debt_alert_threshold}</FieldError>
                  </FieldContent>
                </Field>

                <div className="grid grid-cols-2 gap-3 pt-2 sm:flex sm:justify-end">
                  <Button
                    type="button"
                    variant="outline"
                    onClick={() => setIsEditing(false)}
                  >
                    {t(`${scope}.cancel`)}
                  </Button>
                  <Button type="submit" disabled={processing}>
                    {t(`${scope}.submit`)}
                  </Button>
                </div>
              </>
            )}
          </Form>
        </div>
      ) : (
        <div className="flex items-center justify-between rounded-lg border border-[#E5E5E5] bg-[#F5F5F5] p-4 dark:border-neutral-800 dark:bg-neutral-900">
          <span className="text-sm font-medium text-[#737373] dark:text-neutral-400">
            {t(`${scope}.threshold`)}
          </span>
          <span className="text-base font-medium text-foreground">
            {formatMoney(threshold)}
          </span>
        </div>
      )}
    </section>
  )
}
