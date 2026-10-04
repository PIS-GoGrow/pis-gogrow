import { Transition } from "@headlessui/react"
import { Form, Head, router, usePage } from "@inertiajs/react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import DeleteUser from "@/components/delete-user"
import HeadingSmall from "@/components/heading-small"
import { Button } from "@/components/ui/button"
import { Field, FieldError, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { Switch } from "@/components/ui/switch"
import AppLayout from "@/layouts/app-layout"
import SettingsLayout from "@/layouts/settings/layout"
import { settingsProfiles } from "@/routes"
import type { BreadcrumbItem, SettingsProfilesShow } from "@/types"

export default function Profile({ provider }: SettingsProfilesShow) {
  const { t } = useTranslation()
  const [updatingHomeDelivery, setUpdatingHomeDelivery] = useState(false)

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

      <SettingsLayout>
        <div className="space-y-6">
          <HeadingSmall
            title={t("pages.settings.profile.heading")}
            description={t("pages.settings.profile.description")}
          />

          <Form
            action={settingsProfiles.update()}
            options={{
              preserveScroll: true,
            }}
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

                {provider && (
                  <div className="space-y-4 border-t pt-8">
                    <HeadingSmall
                      title={t("pages.settings.profile.home_delivery.heading")}
                    />

                    <Field
                      orientation="horizontal"
                      className="rounded-lg border p-4"
                    >
                      <FieldLabel htmlFor="home_delivery">
                        {t("pages.settings.profile.home_delivery.label")}
                      </FieldLabel>
                      <Switch
                        id="home_delivery"
                        defaultChecked={provider.home_delivery}
                        disabled={updatingHomeDelivery}
                        onCheckedChange={(homeDelivery) => {
                          setUpdatingHomeDelivery(true)
                          router.patch(
                            settingsProfiles.update(),
                            { home_delivery: homeDelivery },
                            {
                              preserveScroll: true,
                              onFinish: () => setUpdatingHomeDelivery(false),
                            },
                          )
                        }}
                      />
                    </Field>
                  </div>
                )}
              </>
            )}
          </Form>
        </div>

        <DeleteUser />
      </SettingsLayout>
    </AppLayout>
  )
}
