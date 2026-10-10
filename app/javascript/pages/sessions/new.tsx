import { Form, Head } from "@inertiajs/react"
import { useTranslation } from "react-i18next"

import { GoogleMark } from "@/components/branding/google-mark"
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { Button } from "@/components/ui/button"
import { Field, FieldGroup, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { Spinner } from "@/components/ui/spinner"
import AuthLayout from "@/layouts/auth-layout"
import { readAuthenticityToken } from "@/lib/utils"
import { sessions } from "@/routes"
import type { SessionsNew } from "@/types"

interface Props extends SessionsNew {
  errors?: { auth?: string }
}

export default function Login({ errors, dev_login_enabled }: Props) {
  const { t } = useTranslation()

  return (
    <AuthLayout
      title={t("pages.sessions.new.heading")}
      description={t("pages.sessions.new.description")}
    >
      <Head title={t("pages.sessions.new.title")} />

      {errors?.auth && (
        <Alert variant="destructive" role="alert">
          <AlertTitle>{t("pages.sessions.new.auth_error_title")}</AlertTitle>
          <AlertDescription>{errors.auth}</AlertDescription>
        </Alert>
      )}

      {/*
        Full-page navigation (not an Inertia visit): OmniAuth needs to
        redirect the whole browser to accounts.google.com, and
        omniauth-rails_csrf_protection requires the request to be a POST.
      */}
      <form action="/auth/google_oauth2" method="post">
        <input
          type="hidden"
          name="authenticity_token"
          value={readAuthenticityToken()}
        />
        <Button type="submit" className="h-12 w-full gap-2 rounded-[10px] text-base font-medium">
          <span className="size-4"><GoogleMark /></span>
          {t("pages.sessions.new.continue_with_google")}
        </Button>
      </form>

      {dev_login_enabled && (
        <>
          <div className="flex items-center gap-3">
            <span className="bg-border h-px flex-1" />
            <span className="text-muted-foreground text-xs uppercase">
              {t("pages.sessions.new.or")}
            </span>
            <span className="bg-border h-px flex-1" />
          </div>

          {/*
            Las credenciales incorrectas vuelven como flash, no como errores de
            campo: sessions#create redirige con alert en lugar de renderizar.
          */}
          <Form
            action={sessions.create()}
            resetOnSuccess={["password"]}
            disableWhileProcessing
            className="flex flex-col gap-6"
          >
            {({ processing }) => (
              <FieldGroup>
                <Field>
                  <FieldLabel htmlFor="email">
                    {t("common.email_address")}
                  </FieldLabel>
                  <Input
                    id="email"
                    type="email"
                    name="email"
                    required
                    autoComplete="email"
                    placeholder={t("common.email_placeholder")}
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
                    autoComplete="current-password"
                  />
                </Field>

                <Button type="submit" className="h-12 w-full rounded-[10px] text-base font-medium">
                  {processing && <Spinner />}
                  {t("pages.sessions.new.submit")}
                </Button>
              </FieldGroup>
            )}
          </Form>
        </>
      )}
    </AuthLayout>
  )
}
