import { Transition } from "@headlessui/react"
import { Form, Head, Link, router, usePage } from "@inertiajs/react"
import { useEffect } from "react"
import { useTranslation } from "react-i18next"

import { Button } from "@/components/ui/button"
import {
  Field,
  FieldError,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import AppLayout from "@/layouts/app-layout"
import SettingsPageLayout from "@/layouts/settings/page-layout"
import {
  adminPreferences,
  identityEmailVerifications,
  settingsEmails,
} from "@/routes"
import type { BreadcrumbItem } from "@/types"

export default function Email() {
  const { t } = useTranslation()

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.settings.email.title"),
      href: settingsEmails.show().url,
    },
  ]

  const { auth } = usePage().props
  const isAdmin = auth.session.role === "admin"

  useEffect(() => {
    if (isAdmin) router.visit(adminPreferences.show().url, { replace: true })
  }, [isAdmin])

  if (isAdmin) return null

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={breadcrumbs[breadcrumbs.length - 1].title} />

      <SettingsPageLayout
        title={t("pages.settings.email.heading")}
        description={t("pages.settings.email.description")}
      >
        <Form
          action={settingsEmails.update()}
          options={{
            preserveScroll: true,
          }}
          resetOnError={["password_challenge"]}
          resetOnSuccess={["password_challenge"]}
          noValidate
          className="space-y-6"
        >
          {({ errors, processing, recentlySuccessful }) => (
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
                    defaultValue={auth.user.email}
                    required
                    autoComplete="username"
                    placeholder={t("common.email_address")}
                  />

                  <FieldError
                    errors={errors.email?.map((message) => ({ message }))}
                  />
                </Field>

                {!auth.user.verified && (
                  <div>
                    <p className="text-muted-foreground -mt-4 text-sm">
                      {t("pages.settings.email.unverified")}{" "}
                      <Link
                        href={identityEmailVerifications.create()}
                        as="button"
                        className="text-foreground underline decoration-neutral-300 underline-offset-4 transition-colors duration-300 ease-out hover:decoration-current! dark:decoration-neutral-500"
                      >
                        {t("pages.settings.email.resend")}
                      </Link>
                    </p>
                  </div>
                )}

                <Field>
                  <FieldLabel htmlFor="password_challenge">
                    {t("common.current_password")}
                  </FieldLabel>

                  <Input
                    id="password_challenge"
                    name="password_challenge"
                    type="password"
                    autoComplete="current-password"
                    placeholder={t("common.current_password")}
                  />

                  <FieldError
                    errors={errors.password_challenge?.map((message) => ({
                      message,
                    }))}
                  />
                </Field>
              </FieldGroup>

              <div className="flex items-center gap-4">
                <Button disabled={processing}>{t("common.save")}</Button>

                <Transition
                  show={recentlySuccessful}
                  enter="transition ease-in-out"
                  enterFrom="opacity-0"
                  leave="transition ease-in-out"
                  leaveTo="opacity-0"
                >
                  <p className="text-sm text-neutral-600">
                    {t("common.saved")}
                  </p>
                </Transition>
              </div>
            </>
          )}
        </Form>
      </SettingsPageLayout>
    </AppLayout>
  )
}
