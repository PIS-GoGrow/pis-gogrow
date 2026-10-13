import { Head } from "@inertiajs/react"
import { useTranslation } from "react-i18next"

import PasswordSetupForm from "@/components/password-setup-form"
import AuthLayout from "@/layouts/auth-layout"
import { providerInvitations } from "@/routes"
import type { ProviderInvitationsShow } from "@/types"

export default function ProviderInvitation({ email }: ProviderInvitationsShow) {
  const { t } = useTranslation()

  return (
    <AuthLayout
      title={t("pages.provider_invitations.show.heading")}
      description={t("pages.provider_invitations.show.description")}
    >
      <Head title={t("pages.provider_invitations.show.title")} />

      <PasswordSetupForm
        action={providerInvitations.update()}
        email={email}
        submitLabel={t("pages.provider_invitations.show.submit")}
      />
    </AuthLayout>
  )
}
