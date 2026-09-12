import { Head, Link } from "@inertiajs/react"
import { useTranslation } from "react-i18next"

import { GoogleMark } from "@/components/branding/google-mark"
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { Button } from "@/components/ui/button"
import AuthLayout from "@/layouts/auth-layout"
import { readAuthenticityToken } from "@/lib/utils"
import { sessions } from "@/routes"

interface Props {
	id: number | string
	roles: string[]
}

export default function ChooseRole({ id, roles }: Props) {
  const { t } = useTranslation()

	return (
    <AuthLayout
      title={t("pages.sessions.edit.heading")}
      description={t("pages.sessions.edit.description")}
    >
      <div className={`mx-auto grid grid-cols-${ roles.length } gap-2`}>
		{ roles.includes("provider") && (
        <Button asChild variant="outline">
          <Link href={sessions.update(id)} data={{ role: 'provider' }}>
            {t("common.provider")}
          </Link>
        </Button>
		)}
		{ roles.includes("consumer") && (
        <Button asChild variant="outline">
          <Link href={sessions.update(id)} data={{ role: 'consumer' }}>
            {t("common.consumer")}
          </Link>
        </Button>
		)}
		{ roles.includes("admin") && (
        <Button asChild variant="outline">
          <Link href={sessions.update(id)} data={{ role: 'admin' }}>
            {t("common.admin")}
          </Link>
        </Button>
		)}
      </div>
	</AuthLayout>
	)
}
