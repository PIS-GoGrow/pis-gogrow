import { Form, Head } from "@inertiajs/react"
import { useTranslation } from "react-i18next"

import TextLink from "@/components/text-link"
import { Button } from "@/components/ui/button"
import {
  Field,
  FieldError,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { Spinner } from "@/components/ui/spinner"
import AuthLayout from "@/layouts/auth-layout"
import { sessions, users } from "@/routes"

export default function Register() {
  const { t } = useTranslation()

  return (
    <AuthLayout
      title={t("pages.users.new.heading")}
      description={t("pages.users.new.description")}
    >
      <Head title={t("pages.users.new.title")} />
      <Form
        action={users.create()}
        resetOnSuccess={["password", "password_confirmation"]}
        disableWhileProcessing
        className="flex flex-col gap-6"
      >
        {({ processing, errors }) => (
          <>
            <FieldGroup>
              <Field>
                <FieldLabel htmlFor="name">{t("common.name")}</FieldLabel>
                <Input
                  id="name"
                  type="text"
                  name="name"
                  required
                  autoFocus
                  tabIndex={1}
                  autoComplete="name"
                  disabled={processing}
                  placeholder={t("common.full_name")}
                />
                <FieldError
                  errors={errors.name?.map((message) => ({ message }))}
                />
              </Field>

              <Field>
                <FieldLabel htmlFor="email">
                  {t("common.email_address")}
                </FieldLabel>
                <Input
                  id="email"
                  type="email"
                  name="email"
                  required
                  tabIndex={2}
                  autoComplete="email"
                  placeholder={t("common.email_placeholder")}
                />
                <FieldError
                  errors={errors.email?.map((message) => ({ message }))}
                />
              </Field>

              <Field>
                <FieldLabel htmlFor="password">
                  {t("common.password")}
                </FieldLabel>
                <Input
                  id="password"
                  type="password"
                  name="password"
                  required
                  tabIndex={3}
                  autoComplete="new-password"
                  placeholder={t("common.password")}
                />
                <FieldError
                  errors={errors.password?.map((message) => ({ message }))}
                />
              </Field>

              <Field>
                <FieldLabel htmlFor="password_confirmation">
                  {t("common.confirm_password")}
                </FieldLabel>
                <Input
                  id="password_confirmation"
                  type="password"
                  name="password_confirmation"
                  required
                  tabIndex={4}
                  autoComplete="new-password"
                  placeholder={t("common.confirm_password")}
                />
                <FieldError
                  errors={errors.password_confirmation?.map((message) => ({
                    message,
                  }))}
                />
              </Field>

              <Button type="submit" className="mt-2 w-full" tabIndex={5}>
                {processing && <Spinner />}
                {t("pages.users.new.submit")}
              </Button>
            </FieldGroup>

            <div className="text-muted-foreground text-center text-sm">
              {t("pages.users.new.have_account")}{" "}
              <TextLink href={sessions.new({})} tabIndex={6}>
                {t("common.log_in")}
              </TextLink>
            </div>
          </>
        )}
      </Form>
    </AuthLayout>
  )
}
