import { Link, usePage } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"
import type { ReactNode } from "react"

import HeadingSmall from "@/components/heading-small"
import PageContainer from "@/components/page-container"
import { Button } from "@/components/ui/button"
import SettingsLayout from "@/layouts/settings/layout"
import { adminAccount } from "@/routes"

interface SettingsPageLayoutProps {
  title: string
  description: string
  children: ReactNode
  adminBackHref?: string
  adminBackLabel?: string
  consumerMobileBackHref?: string
  consumerMobileBackLabel?: string
}

export default function SettingsPageLayout({
  title,
  description,
  children,
  adminBackHref = adminAccount().url,
  adminBackLabel,
  consumerMobileBackHref,
  consumerMobileBackLabel,
}: SettingsPageLayoutProps) {
  const { auth } = usePage().props

  if (auth.session.role === "admin") {
    return (
      <PageContainer
        title={title}
        titleVariant="prominent"
        description={description}
        back={
          <Button variant="ghost" size="icon" asChild>
            <Link href={adminBackHref} aria-label={adminBackLabel}>
              <ArrowLeft aria-hidden="true" />
            </Link>
          </Button>
        }
      >
        <div className="max-w-xl space-y-6">{children}</div>
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
            className="-ml-2 md:hidden"
            asChild
          >
            <Link
              href={consumerMobileBackHref}
              aria-label={consumerMobileBackLabel}
            >
              <ArrowLeft aria-hidden="true" />
            </Link>
          </Button>
        )}

        <HeadingSmall title={title} description={description} />

        {children}
      </div>
    </SettingsLayout>
  )
}
