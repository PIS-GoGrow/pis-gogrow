import { Link, usePage } from "@inertiajs/react"
import { ArrowLeft, ChevronLeft } from "lucide-react"
import type { ReactNode } from "react"
import { useTranslation } from "react-i18next"

import HeadingSmall from "@/components/heading-small"
import PageContainer from "@/components/page-container"
import { Button } from "@/components/ui/button"
import SettingsLayout from "@/layouts/settings/layout"
import { adminAccount, providerAccount } from "@/routes"

interface SettingsPageLayoutProps {
  title: string
  description: string
  children: ReactNode
  adminBackHref?: string
  adminBackLabel?: string
  consumerMobileBackHref?: string
  consumerMobileBackLabel?: string
  titleVariant?: "default" | "prominent"
}

export default function SettingsPageLayout({
  title,
  description,
  children,
  adminBackHref = adminAccount().url,
  adminBackLabel,
  consumerMobileBackHref,
  consumerMobileBackLabel,
  titleVariant = "default",
}: SettingsPageLayoutProps) {
  const { t } = useTranslation()
  const { auth } = usePage().props
  const role = auth.session.role

  // Admin y proveedor navegan sus ajustes desde el hub de Cuenta, con flecha de
  // volver; el empleado usa el panel lateral de configuración.
  if (role === "admin" || role === "provider") {
    const backHref = role === "provider" ? providerAccount().url : adminBackHref
    const backLabel =
      role === "provider"
        ? t("components.settings_layout.back_to_account")
        : adminBackLabel

    return (
      <PageContainer
        title={title}
        titleVariant="prominent"
        description={description}
        back={
          <Button variant="ghost" size="icon" asChild>
            <Link href={backHref} aria-label={backLabel}>
              <ArrowLeft aria-hidden="true" />
            </Link>
          </Button>
        }
      >
        <div
          className={role === "provider" ? "space-y-6" : "max-w-xl space-y-6"}
        >
          {children}
        </div>
      </PageContainer>
    )
  }

  return (
    <SettingsLayout
      compactConsumerMobile={
        auth.session.role === "consumer" && consumerMobileBackHref != null
      }
    >
      <div className="space-y-6">
        {auth.session.role === "consumer" && consumerMobileBackHref && (
          <Button
            variant="ghost"
            size="icon"
            className="-ml-2 size-9 rounded-[10px] md:hidden"
            asChild
          >
            <Link
              href={consumerMobileBackHref}
              aria-label={consumerMobileBackLabel}
            >
              <ChevronLeft aria-hidden="true" className="size-4" />
            </Link>
          </Button>
        )}

        {titleVariant === "prominent" ? (
          <header className="space-y-2">
            <h2 className="text-2xl font-bold tracking-tight text-[#0A0A0A] dark:text-neutral-100">
              {title}
            </h2>
            {description && (
              <p className="text-base text-[#737373] dark:text-neutral-400">
                {description}
              </p>
            )}
          </header>
        ) : (
          <HeadingSmall title={title} description={description} />
        )}

        {children}
      </div>
    </SettingsLayout>
  )
}
