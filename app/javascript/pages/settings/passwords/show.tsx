import { Transition } from "@headlessui/react"
import { Form, Head, router, usePage } from "@inertiajs/react"
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
import { adminPreferences, settingsPasswords } from "@/routes"
import type { BreadcrumbItem } from "@/types"

export default function Password() {
  const { t } = useTranslation()
  const { auth } = usePage().props
  const isAdmin = auth.session.role === "admin"

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.settings.password.title"),
      href: settingsPasswords.show().url,
    },
  ]

  useEffect(() => {
    if (isAdmin) router.visit(adminPreferences.show().url, { replace: true })
  }, [isAdmin])

  if (isAdmin) return null

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={breadcrumbs[breadcrumbs.length - 1].title} />

      <SettingsPageLayout
        title={t("pages.settings.password.heading")}
        description={t("pages.settings.password.description")}
      >
        <Form
          action={settingsPasswords.update()}
          options={{
            preserveScroll: true,
          }}
          resetOnError
          resetOnSuccess
          className="space-y-6"
        >
          {({ errors, processing, recentlySuccessful }) => (
            <>
              <FieldGroup>
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

                <Field>
                  <FieldLabel htmlFor="password">
                    {t("pages.settings.password.new_password")}
                  </FieldLabel>

                  <Input
                    id="password"
                    name="password"
                    type="password"
                    autoComplete="new-password"
                    placeholder={t("pages.settings.password.new_password")}
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
                    name="password_confirmation"
                    type="password"
                    autoComplete="new-password"
                    placeholder={t("common.confirm_password")}
                  />

                  <FieldError
                    errors={errors.password_confirmation?.map((message) => ({
                      message,
                    }))}
                  />
                </Field>
              </FieldGroup>

              <div className="flex items-center gap-4">
                <Button disabled={processing}>
                  {t("pages.settings.password.submit")}
                </Button>

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
