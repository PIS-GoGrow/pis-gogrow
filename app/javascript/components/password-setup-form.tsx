import { Form } from "@inertiajs/react"
import { CircleCheckIcon } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import { Button } from "@/components/ui/button"
import {
  Field,
  FieldError,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { Spinner } from "@/components/ui/spinner"
import { isStrongPassword, passwordRules } from "@/lib/password-policy"
import { cn } from "@/lib/utils"

interface Props {
  action: React.ComponentProps<typeof Form>["action"]
  submitLabel: string
  email?: string | null
}

export default function PasswordSetupForm({
  action,
  submitLabel,
  email,
}: Props) {
  const { t } = useTranslation()
  const [password, setPassword] = useState("")
  const [confirmation, setConfirmation] = useState("")
  const mismatch = confirmation !== "" && confirmation !== password
  const ready = isStrongPassword(password) && confirmation !== "" && !mismatch

  return (
    <Form action={action} className="flex flex-1 flex-col justify-between gap-6">
      {({ processing, errors }) => (
        <>
          <FieldGroup>
            {email != null && (
              <Field>
                <FieldLabel htmlFor="email">
                  {t("common.email_address")}
                </FieldLabel>
                <Input
                  id="email"
                  type="email"
                  value={email}
                  readOnly
                  disabled
                  autoComplete="username"
                />
              </Field>
            )}

            <Field data-invalid={!!errors.password}>
              <FieldLabel htmlFor="password">
                {t("components.password_fields.create_label")}
              </FieldLabel>
              <Input
                id="password"
                type="password"
                name="password"
                autoComplete="new-password"
                autoFocus
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                aria-invalid={!!errors.password}
              />
              <div className="text-muted-foreground text-xs">
                <p className="mb-1">
                  {t("components.password_fields.requirements_title")}
                </p>
                <ul className="space-y-0.5">
                  {passwordRules.map((rule) => (
                    <li
                      key={rule.key}
                      data-met={rule.test(password)}
                      className={cn(
                        "flex items-center gap-2",
                        rule.test(password) && "text-green-600",
                      )}
                    >
                      <CircleCheckIcon
                        className="size-3.5"
                        aria-hidden="true"
                      />
                      {t(`components.password_fields.${rule.key}`)}
                    </li>
                  ))}
                </ul>
              </div>
              <FieldError
                errors={errors.password?.map((message) => ({ message }))}
              />
            </Field>

            <Field data-invalid={mismatch || !!errors.password_confirmation}>
              <FieldLabel htmlFor="password_confirmation">
                {t("components.password_fields.confirm_label")}
              </FieldLabel>
              <Input
                id="password_confirmation"
                type="password"
                name="password_confirmation"
                autoComplete="new-password"
                value={confirmation}
                onChange={(event) => setConfirmation(event.target.value)}
                aria-invalid={mismatch || !!errors.password_confirmation}
              />
              {mismatch && (
                <p className="text-muted-foreground text-xs">
                  {t("components.password_fields.mismatch")}
                </p>
              )}
              <FieldError
                errors={errors.password_confirmation?.map((message) => ({
                  message,
                }))}
              />
            </Field>
          </FieldGroup>

          <div className="mt-auto pt-6">
            <Button
              type="submit"
              size="lg"
              className="h-12 w-full rounded-[10px] bg-[#171717] text-base font-medium text-[#FAFAFA] hover:bg-[#171717]/90 disabled:opacity-50 dark:bg-white dark:text-black dark:hover:bg-white/90"
              disabled={!ready || processing}
            >
              {processing && <Spinner />}
              {submitLabel}
            </Button>
          </div>
        </>
      )}
    </Form>
  )
}
