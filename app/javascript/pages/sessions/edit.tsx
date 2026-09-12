import { Head, Link } from "@inertiajs/react"
import { useTranslation } from "react-i18next"

import { Button } from "@/components/ui/button"
import AuthLayout from "@/layouts/auth-layout"
import { sessions } from "@/routes"

interface Props {
  id: number | string
  roles: string[]
}

interface RoleButtonProps {
  id: number | string
  role: string
  roles: string[]
}

function RoleButton({ id, role, roles }: RoleButtonProps) {
  const { t } = useTranslation()

  return (
    <>
      {roles.includes(role) && (
        <Button asChild variant="outline">
          <Link href={sessions.update(id)} data={{ role: role }}>
            {t("common." + role)}
          </Link>
        </Button>
      )}
    </>
  )
}

export default function ChooseRole({ id, roles }: Props) {
  const { t } = useTranslation()

  return (
    <AuthLayout
      title={t("pages.sessions.edit.heading")}
      description={t("pages.sessions.edit.description")}
    >
      <Head title={t("pages.sessions.edit.title")} />

      <div className={`mx-auto grid grid-cols-${roles.length} gap-2`}>
        <RoleButton id={id} role="provider" roles={roles} />
        <RoleButton id={id} role="consumer" roles={roles} />
        <RoleButton id={id} role="admin" roles={roles} />
      </div>
    </AuthLayout>
  )
}
