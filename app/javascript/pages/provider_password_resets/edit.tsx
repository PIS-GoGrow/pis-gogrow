import { Head } from "@inertiajs/react"
import { useTranslation } from "react-i18next"

import PasswordSetupForm from "@/components/password-setup-form"
import AuthLayout from "@/layouts/auth-layout"
import { providerPasswordResets } from "@/routes"

export default function ProviderNewPassword() {
  const { t } = useTranslation()

  return (
    <AuthLayout
      title={t("pages.provider_password_resets.edit.heading")}
      description={t("pages.provider_password_resets.edit.description")}
    >
      <Head title={t("pages.provider_password_resets.edit.title")} />

      <PasswordSetupForm
        action={providerPasswordResets.update()}
        submitLabel={t("pages.provider_password_resets.edit.submit")}
      />
    </AuthLayout>
  )
}
