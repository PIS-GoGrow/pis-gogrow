import { Form } from "@inertiajs/react"
import { PencilIcon } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import { Button } from "@/components/ui/button"
import {
  Card,
  CardAction,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
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
    <Card>
      <CardHeader>
        <CardTitle>{t(`${scope}.title`)}</CardTitle>
        <CardDescription>{t(`${scope}.description`)}</CardDescription>

        {!isEditing && (
          <CardAction>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setIsEditing(true)}
            >
              <PencilIcon />
              {t(`${scope}.edit`)}
            </Button>
          </CardAction>
        )}
      </CardHeader>
      <CardContent>
        {isEditing ? (
          <Form
            action={adminDebtAlert()}
            options={{ preserveScroll: true }}
            onSuccess={() => setIsEditing(false)}
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
                        step="1"
                        className="w-32 text-base"
                        defaultValue={threshold}
                        aria-invalid={!!errors.debt_alert_threshold}
                      />
                    </div>
                    <FieldError>{errors.debt_alert_threshold}</FieldError>
                  </FieldContent>
                </Field>

                <div className="flex justify-end gap-2">
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
        ) : (
          <dl className="bg-muted rounded-lg px-4">
            <div className="flex items-center justify-between py-3">
              <dt className="text-muted-foreground">
                {t(`${scope}.threshold`)}
              </dt>
              <dd className="text-lg font-semibold">
                {formatMoney(threshold)}
              </dd>
            </div>
          </dl>
        )}
      </CardContent>
    </Card>
  )
}
