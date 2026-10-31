import { Head, Link } from "@inertiajs/react"
import { Mail } from "lucide-react"
import { useTranslation } from "react-i18next"

import { GoogleMark } from "@/components/branding/google-mark"
import DevLoginForm from "@/components/dev-login-form"
import FeatureCarousel from "@/components/provider/feature-carousel"
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { Button } from "@/components/ui/button"
import AuthLayout from "@/layouts/auth-layout"
import { readAuthenticityToken } from "@/lib/utils"
import type { HomeIndex } from "@/types"

interface Props extends HomeIndex {
  errors?: { auth?: string }
}

export default function Home({ variant, dev_login_enabled, errors }: Props) {
  const { t } = useTranslation()

  return (
    <AuthLayout
      title={t(`pages.home.${variant}.heading`)}
      description={t(`pages.home.${variant}.description`)}
    >
      <Head title={t("pages.home.title")} />

      {errors?.auth && (
        <Alert variant="destructive" role="alert">
          <AlertTitle>{t("pages.sessions.new.auth_error_title")}</AlertTitle>
          <AlertDescription>{errors.auth}</AlertDescription>
        </Alert>
      )}

      {variant === "provider" ? (
        <div className="flex flex-col gap-6">
          <FeatureCarousel />

          <Button
            asChild
            size="lg"
            className="h-12 w-full rounded-[10px] bg-[#171717] text-base font-medium text-[#FAFAFA] hover:bg-[#171717]/90"
          >
            <Link href="/proveedor/iniciar-sesion">
              <Mail className="mr-2 size-4" aria-hidden="true" />
              {t("pages.home.provider.sign_in")}
            </Link>
          </Button>

          {dev_login_enabled && <DevLoginForm origin="/proveedor" />}
        </div>
      ) : (
        <>
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
            <input
              type="hidden"
              name="origin"
              value={variant === "admin" ? "/rrhh" : "/consumidor"}
            />
            <Button
              type="submit"
              size="lg"
              className="h-12 w-full rounded-[10px] bg-[#171717] text-base font-medium text-[#FAFAFA] hover:bg-[#171717]/90"
            >
              <GoogleMark />
              {t(`pages.home.${variant}.sign_in`)}
            </Button>
          </form>

          {dev_login_enabled && (
            <DevLoginForm
              origin={variant === "admin" ? "/rrhh" : "/consumidor"}
            />
          )}
        </>
      )}
    </AuthLayout>
  )
}
