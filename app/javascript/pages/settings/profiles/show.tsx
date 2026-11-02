import { Transition } from "@headlessui/react"
import { Form, Head, usePage } from "@inertiajs/react"
import { useTranslation } from "react-i18next"

import DeleteUser from "@/components/delete-user"
import { Button } from "@/components/ui/button"
import {
  Field,
  FieldDescription,
  FieldError,
  FieldLabel,
} from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import AppLayout from "@/layouts/app-layout"
import SettingsPageLayout from "@/layouts/settings/page-layout"
import { adminPreferences, settingsProfiles } from "@/routes"
import type { BreadcrumbItem, SettingsProfilesShow } from "@/types"

export default function Profile({ phone }: SettingsProfilesShow) {
  const { t } = useTranslation()

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.settings.profile.title"),
      href: settingsProfiles.show().url,
    },
  ]

  const { auth } = usePage().props

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={breadcrumbs[breadcrumbs.length - 1].title} />

      <SettingsPageLayout
        title={t("pages.settings.profile.heading")}
        description={t("pages.settings.profile.description")}
        adminBackHref={adminPreferences.show().url}
        adminBackLabel={t("pages.settings.profile.back")}
      >
        <Form
          action={settingsProfiles.update()}
          options={{
            preserveScroll: true,
          }}
          noValidate
          className="space-y-8"
        >
          {({ errors, processing, recentlySuccessful }) => (
            <>
              <div className="space-y-4">
                <Field>
                  <FieldLabel htmlFor="name">{t("common.name")}</FieldLabel>

                  <Input
                    id="name"
                    name="name"
                    defaultValue={auth.user.name}
                    required
                    autoComplete="name"
                    placeholder={t("common.full_name")}
                  />

                  <FieldError
                    errors={errors.name?.map((message) => ({ message }))}
                  />
                </Field>

                <Field>
                  <FieldLabel htmlFor="phone">
                    {t("pages.settings.profile.phone")}
                  </FieldLabel>

                  <Input
                    id="phone"
                    name="phone"
                    type="tel"
                    defaultValue={phone ?? ""}
                    autoComplete="tel"
                    placeholder={t("pages.settings.profile.phone_placeholder")}
                  />

                  <FieldDescription>
                    {t("pages.settings.profile.phone_description")}
                  </FieldDescription>

                  <FieldError
                    errors={errors.phone?.map((message) => ({ message }))}
                  />
                </Field>

                {auth.session.role === "admin" && (
                  <Field>
                    <FieldLabel htmlFor="email">
                      {t("common.email_address")}
                    </FieldLabel>
                    <Input
                      id="email"
                      type="email"
                      value={auth.user.email}
                      readOnly
                      aria-readonly="true"
                    />
                    <FieldDescription>
                      {t("pages.settings.profile.email_description")}
                    </FieldDescription>
                  </Field>
                )}

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
              </div>
            </>
          )}
        </Form>

        {auth.session.role !== "admin" && <DeleteUser />}
      </SettingsPageLayout>
    </AppLayout>
  )
}
