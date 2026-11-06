import { Transition } from "@headlessui/react"
import { Form, Head, Link, usePage } from "@inertiajs/react"
import { useTranslation } from "react-i18next"

import AppearanceTabs from "@/components/appearance-tabs"
import DeleteUser from "@/components/delete-user"
import HeadingSmall from "@/components/heading-small"
import { Button } from "@/components/ui/button"
import {
  Field,
  FieldDescription,
  FieldError,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { Separator } from "@/components/ui/separator"
import AppLayout from "@/layouts/app-layout"
import SettingsPageLayout from "@/layouts/settings/page-layout"
import {
  adminPreferences,
  identityEmailVerifications,
  settingsEmails,
  settingsPasswords,
  settingsProfiles,
} from "@/routes"
import type { BreadcrumbItem, SettingsProfilesShow } from "@/types"

export default function Profile({ phone }: SettingsProfilesShow) {
  const { t } = useTranslation()
  const { auth } = usePage().props
  const isConsumer = auth.session.role === "consumer"

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: isConsumer
        ? t("pages.consumer_profiles.show.title")
        : t("pages.settings.profile.title"),
      href: settingsProfiles.show().url,
    },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={breadcrumbs[breadcrumbs.length - 1].title} />

      <SettingsPageLayout
        title={
          isConsumer
            ? t("pages.consumer_profiles.show.title")
            : t("pages.settings.profile.heading")
        }
        description={
          isConsumer
            ? t("pages.consumer_profiles.show.account_description")
            : t("pages.settings.profile.description")
        }
        adminBackHref={adminPreferences.show().url}
        adminBackLabel={t("pages.settings.profile.back")}
      >
        {isConsumer && (
          <HeadingSmall
            title={t("pages.settings.profile.heading")}
            description={t("pages.settings.profile.description")}
          />
        )}

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

        {isConsumer && (
          <>
            <Separator className="my-8" />

            <div className="space-y-4">
              <HeadingSmall
                title={t("pages.settings.email.heading")}
                description={t("pages.settings.email.description")}
              />

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
                        <FieldLabel htmlFor="consumer_email">
                          {t("common.email_address")}
                        </FieldLabel>

                        <Input
                          id="consumer_email"
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
                        <FieldLabel htmlFor="email_password_challenge">
                          {t("common.current_password")}
                        </FieldLabel>

                        <Input
                          id="email_password_challenge"
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
            </div>

            <Separator className="my-8" />

            <div className="space-y-4">
              <HeadingSmall
                title={t("pages.settings.password.heading")}
                description={t("pages.settings.password.description")}
              />

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
                        <FieldLabel htmlFor="password_password_challenge">
                          {t("common.current_password")}
                        </FieldLabel>

                        <Input
                          id="password_password_challenge"
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
                          placeholder={t(
                            "pages.settings.password.new_password",
                          )}
                        />

                        <FieldError
                          errors={errors.password?.map((message) => ({
                            message,
                          }))}
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
                          errors={errors.password_confirmation?.map(
                            (message) => ({
                              message,
                            }),
                          )}
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
            </div>

            <Separator className="my-8" />

            <div className="space-y-4">
              <HeadingSmall
                title={t("pages.settings.appearance.title")}
                description={t("pages.settings.appearance.description")}
              />
              <AppearanceTabs />
            </div>

            <Separator className="my-8" />

            <DeleteUser />
          </>
        )}
      </SettingsPageLayout>
    </AppLayout>
  )
}
