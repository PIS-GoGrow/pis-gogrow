import { Form, Head } from "@inertiajs/react"
import { useTranslation } from "react-i18next"

import TextLink from "@/components/text-link"
import { Button } from "@/components/ui/button"
import { Field, FieldError, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { Spinner } from "@/components/ui/spinner"
import AuthLayout from "@/layouts/auth-layout"
import { identityPasswordResets, sessions } from "@/routes"

export default function ForgotPassword() {
  const { t } = useTranslation()

  return (
    <AuthLayout
      title={t("pages.password_resets.new.title")}
      description={t("pages.password_resets.new.description")}
    >
      <Head title={t("pages.password_resets.new.title")} />

      <div className="space-y-6">
        <Form action={identityPasswordResets.create()}>
          {({ processing, errors }) => (
            <>
              <Field>
                <FieldLabel htmlFor="email">
                  {t("common.email_address")}
                </FieldLabel>
                <Input
                  id="email"
                  type="email"
                  name="email"
                  autoComplete="off"
                  autoFocus
                  placeholder={t("common.email_placeholder")}
                />
                <FieldError
                  errors={errors.email?.map((message) => ({ message }))}
                />
              </Field>

              <div className="my-6 flex items-center justify-start">
                <Button className="w-full" disabled={processing}>
                  {processing && <Spinner />}
                  {t("pages.password_resets.new.submit")}
                </Button>
              </div>
            </>
          )}
        </Form>
        <div className="text-muted-foreground space-x-1 text-center text-sm">
          <span>{t("pages.password_resets.new.return_to")}</span>
          <TextLink href={sessions.new({})}>
            {t("pages.password_resets.new.log_in")}
          </TextLink>
        </div>
      </div>
    </AuthLayout>
  )
}
