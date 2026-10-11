import { Head } from "@inertiajs/react"
import { useTranslation } from "react-i18next"

import CompletedSheet from "@/components/completed-sheet"
import PasswordSetupForm from "@/components/password-setup-form"
import AuthLayout from "@/layouts/auth-layout"
import { providerPasswordResets, providerSessions } from "@/routes"
import type { ProviderPasswordResetsEdit } from "@/types"

export default function ProviderNewPassword({
  completed,
}: ProviderPasswordResetsEdit) {
  const { t } = useTranslation()

  return (
    <AuthLayout
      title={t("pages.provider_password_resets.edit.heading")}
      description={t("pages.provider_password_resets.edit.description")}
    >
      <Head title={t("pages.provider_password_resets.edit.title")} />

      {!completed && (
        <PasswordSetupForm
          action={providerPasswordResets.update()}
          submitLabel={t("pages.provider_password_resets.edit.submit")}
        />
      )}

      <CompletedSheet
        open={completed}
        title={t("pages.provider_password_resets.edit.completed_title")}
        description={t(
          "pages.provider_password_resets.edit.completed_description",
        )}
        href={providerSessions.new().url}
      />
    </AuthLayout>
  )
}
