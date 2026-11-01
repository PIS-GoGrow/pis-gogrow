import { Head } from "@inertiajs/react"
import { useTranslation } from "react-i18next"

import FeatureCarousel from "@/components/provider/feature-carousel"
import { Button } from "@/components/ui/button"
import AuthLayout from "@/layouts/auth-layout"
import type { ProviderWelcomesShow } from "@/types"

export default function ProviderWelcome({
  username,
  company_name,
  invitation_path,
}: ProviderWelcomesShow) {
  const { t } = useTranslation()

  return (
    <AuthLayout
      title={t("pages.provider_welcomes.show.heading")}
      description={t("pages.provider_welcomes.show.description", {
        username,
        company_name,
      })}
    >
      <Head title={t("pages.provider_welcomes.show.title")} />

      <FeatureCarousel />

      <Button asChild size="lg" className="w-full">
        <a href={invitation_path}>{t("pages.provider_welcomes.show.join")}</a>
      </Button>
    </AuthLayout>
  )
}
