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
      fullHeight
    >
      <Head title={t("pages.provider_welcomes.show.title")} />

      <div className="flex flex-1 flex-col justify-between gap-6">
        <FeatureCarousel />

        <div className="mt-auto pt-6">
          <Button
            asChild
            size="lg"
            className="h-12 w-full rounded-[10px] bg-[#171717] text-base font-medium text-[#FAFAFA] hover:bg-[#171717]/90 dark:bg-white dark:text-black dark:hover:bg-white/90"
          >
            <a href={invitation_path}>{t("pages.provider_welcomes.show.join")}</a>
          </Button>
        </div>
      </div>
    </AuthLayout>
  )
}
