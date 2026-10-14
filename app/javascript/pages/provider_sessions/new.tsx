import { Form, Head } from "@inertiajs/react"
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
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet"
import { Spinner } from "@/components/ui/spinner"
import AuthLayout from "@/layouts/auth-layout"
import { providerPasswordResets, providerSessions } from "@/routes"

export default function ProviderSignIn() {
  const { t } = useTranslation()
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [forgotOpen, setForgotOpen] = useState(false)

  return (
    <AuthLayout
      title={t("pages.provider_sessions.new.heading")}
      description={t("pages.provider_sessions.new.description")}
    >
      <Head title={t("pages.provider_sessions.new.title")} />

      <Form
        action={providerSessions.create()}
        resetOnSuccess={["password"]}
        className="flex flex-col gap-6"
      >
        {({ processing }) => (
          <>
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
                  autoFocus
                  autoComplete="username"
                  value={email}
                  onChange={(event) => setEmail(event.target.value)}
                  placeholder={t(
                    "pages.provider_sessions.new.email_placeholder",
                  )}
                />
              </Field>

              <Field>
                <div className="flex items-center justify-between">
                  <FieldLabel htmlFor="password">
                    {t("common.password")}
                  </FieldLabel>
                  <Button
                    type="button"
                    variant="link"
                    size="sm"
                    className="h-auto p-0"
                    onClick={() => setForgotOpen(true)}
                  >
                    {t("pages.provider_sessions.new.forgot_password")}
                  </Button>
                </div>
                <Input
                  id="password"
                  type="password"
                  name="password"
                  required
                  autoComplete="current-password"
                  value={password}
                  onChange={(event) => setPassword(event.target.value)}
                />
              </Field>
            </FieldGroup>

            <Button
              type="submit"
              size="lg"
              className="w-full"
              disabled={!email || !password || processing}
            >
              {processing && <Spinner />}
              {t("pages.provider_sessions.new.submit")}
            </Button>
          </>
        )}
      </Form>

      <Sheet open={forgotOpen} onOpenChange={setForgotOpen}>
        <SheetContent
          side="bottom"
          className="mx-auto w-full max-w-md rounded-t-3xl p-6"
        >
          <SheetHeader className="p-0">
            <SheetTitle>
              {t("pages.provider_sessions.new.forgot.title")}
            </SheetTitle>
            <SheetDescription>
              {t("pages.provider_sessions.new.forgot.description")}
            </SheetDescription>
          </SheetHeader>

          <Form
            action={providerPasswordResets.create()}
            className="flex flex-col gap-4"
          >
            {({ processing, errors }) => (
              <>
                <Field data-invalid={!!errors.email}>
                  <FieldLabel htmlFor="forgot_email">
                    {t("common.email_address")}
                  </FieldLabel>
                  <Input
                    id="forgot_email"
                    type="email"
                    name="email"
                    required
                    autoComplete="email"
                    defaultValue={email}
                    aria-invalid={!!errors.email}
                    placeholder={t(
                      "pages.provider_sessions.new.email_placeholder",
                    )}
                  />
                  <FieldError
                    errors={errors.email?.map((message) => ({ message }))}
                  />
                </Field>
                <Button
                  type="submit"
                  size="lg"
                  className="w-full"
                  disabled={processing}
                >
                  {processing && <Spinner />}
                  {t("pages.provider_sessions.new.forgot.submit")}
                </Button>
              </>
            )}
          </Form>
        </SheetContent>
      </Sheet>
    </AuthLayout>
  )
}
