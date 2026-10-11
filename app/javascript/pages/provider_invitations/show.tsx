import { Head } from "@inertiajs/react"
import { useTranslation } from "react-i18next"

import CompletedSheet from "@/components/completed-sheet"
import PasswordSetupForm from "@/components/password-setup-form"
import AuthLayout from "@/layouts/auth-layout"
import { providerInvitations, providerSessions } from "@/routes"
import type { ProviderInvitationsShow } from "@/types"

export default function ProviderInvitation({
  email,
  completed,
}: ProviderInvitationsShow) {
  const { t } = useTranslation()

  return (
    <AuthLayout
      title={t("pages.provider_invitations.show.heading")}
      description={t("pages.provider_invitations.show.description")}
    >
      <Head title={t("pages.provider_invitations.show.title")} />

      {!completed && (
        <PasswordSetupForm
          action={providerInvitations.update()}
          email={email}
          submitLabel={t("pages.provider_invitations.show.submit")}
        />
      )}

      <CompletedSheet
        open={completed}
        title={t("pages.provider_invitations.show.completed_title")}
        description={t("pages.provider_invitations.show.completed_description")}
        href={providerSessions.new().url}
      />
    </AuthLayout>
  )
}
