import { Head, Link, usePage } from "@inertiajs/react"
import { X } from "lucide-react"
import { useTranslation } from "react-i18next"

import { Button } from "@/components/ui/button"
import {
  adminDashboard,
  consumerDashboard,
  home,
  providerDashboard,
  sessions,
} from "@/routes"

export default function NotFound() {
  const { t } = useTranslation()
  const { auth } = usePage().props

  const destination = auth.session
    ? {
        consumer: {
          href: consumerDashboard.index(),
          label: t("pages.errors.not_found.go_to_menu"),
        },
        provider: {
          href: providerDashboard.index(),
          label: t("pages.errors.not_found.go_to_panel"),
        },
        admin: {
          href: adminDashboard.index(),
          label: t("pages.errors.not_found.go_to_panel"),
        },
      }[auth.session.role]
    : {
        href: sessions.new(),
        label: t("pages.errors.not_found.sign_in"),
      }

  return (
    <>
      <Head title={t("pages.errors.not_found.title")} />

      <main className="bg-background text-foreground flex min-h-svh flex-col px-6 py-8 md:mx-auto md:my-8 md:min-h-0 md:max-w-3xl md:rounded-2xl md:border md:p-8">
        <div className="flex flex-1 flex-col items-center justify-center pb-16">
          <div className="bg-primary text-primary-foreground flex size-20 items-center justify-center rounded-full">
            <X aria-hidden="true" className="size-10" strokeWidth={2.5} />
          </div>

          <h1 className="mt-7 text-center text-2xl font-bold">
            {t("pages.errors.not_found.heading")}
          </h1>
          <p className="text-muted-foreground mt-2 max-w-sm text-center text-base leading-6">
            {t("pages.errors.not_found.description")}
          </p>
        </div>

        <div className="space-y-3">
          <Button asChild className="h-12 w-full">
            <Link href={destination.href}>{destination.label}</Link>
          </Button>
          <Button asChild variant="secondary" className="h-12 w-full">
            <Link href={home.index()}>
              {t("pages.errors.not_found.back_home")}
            </Link>
          </Button>
        </div>
      </main>
    </>
  )
}
