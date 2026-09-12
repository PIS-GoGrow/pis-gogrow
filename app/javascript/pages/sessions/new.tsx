import { Head, Link } from "@inertiajs/react"
import { useTranslation } from "react-i18next"

import { GoogleMark } from "@/components/branding/google-mark"
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { Button } from "@/components/ui/button"
import AuthLayout from "@/layouts/auth-layout"
import { readAuthenticityToken } from "@/lib/utils"
import { sessions } from "@/routes"

interface Props {
  role: string
  errors?: { auth?: string }
}

export default function Login({ role, errors }: Props) {
  const { t } = useTranslation()

  return (
    <AuthLayout
      title={t("pages.sessions.new.heading")}
      description={t("pages.sessions.new.description")}
    >
      <Head title={t("pages.sessions.new.title")} />

      {errors?.auth && (
        <Alert variant="destructive" role="alert">
          <AlertTitle>{t("pages.sessions.new.auth_error_title")}</AlertTitle>
          <AlertDescription>{errors.auth}</AlertDescription>
        </Alert>
      )}

      <div className="mx-auto grid grid-cols-3 gap-2">
        <Button asChild variant={role != "provider" ? "outline" : "default"}>
          <Link href={sessions.new({ role: "provider" })}>
            {t("common.provider")}
          </Link>
        </Button>
        <Button asChild variant={role != "consumer" ? "outline" : "default"}>
          <Link href={sessions.new({ role: "consumer" })}>
            {t("common.consumer")}
          </Link>
        </Button>
        <Button asChild variant={role != "admin" ? "outline" : "default"}>
          <Link href={sessions.new({ role: "admin" })}>
            {t("common.admin")}
          </Link>
        </Button>
      </div>

      {/*
        Full-page navigation (not an Inertia visit): OmniAuth needs to
        redirect the whole browser to accounts.google.com, and
        omniauth-rails_csrf_protection requires the request to be a POST.
      */}
      <form action="/auth/google_oauth2" method="post">
        <input
          type="hidden"
          name="authenticity_token"
          value={readAuthenticityToken()}
        />
        <Button type="submit" variant="outline" className="w-full">
          <GoogleMark />
          {t("pages.sessions.new.continue_with_google")}
        </Button>
      </form>
    </AuthLayout>
  )
}
