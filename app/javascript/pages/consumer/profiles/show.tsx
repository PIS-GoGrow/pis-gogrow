import { Head, router, usePage } from "@inertiajs/react"
import { LogOut } from "lucide-react"
import { useTranslation } from "react-i18next"

import BenefitSummaryCard from "@/components/benefit-summary-card"
import { ConsumerMobileNav } from "@/components/consumer/consumer-mobile-nav"
import PageContainer from "@/components/page-container"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Button } from "@/components/ui/button"
import { useFormatters } from "@/hooks/use-formatters"
import { useInitials } from "@/hooks/use-initials"
import AppLayout from "@/layouts/app-layout"
import { consumerProfiles, sessions } from "@/routes"
import type { BreadcrumbItem, ConsumerProfilesShow } from "@/types"

function Row({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-baseline justify-between gap-4 border-b py-3">
      <dt className="text-muted-foreground text-sm">{label}</dt>
      <dd className="text-right text-sm font-medium">{value}</dd>
    </div>
  )
}

export default function Show({
  benefit,
  benefit_summary,
}: ConsumerProfilesShow) {
  const { t } = useTranslation()
  const { auth } = usePage().props
  const getInitials = useInitials()
  const { formatMoney } = useFormatters()
  const page = "pages.consumer_profiles.show"

  const breadcrumbs: BreadcrumbItem[] = [
    { title: t(`${page}.title`), href: consumerProfiles.show().url },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t(`${page}.title`)} />

      <PageContainer
        title={t(`${page}.title`)}
        titleVariant="prominent"
        actions={
          <Button
            variant="ghost"
            className="gap-1.5 px-1 font-semibold text-red-700 hover:text-red-700 has-[>svg]:px-1 dark:text-red-400 dark:hover:text-red-400"
            asChild
          >
            {/* El Link con method no servía: combinándolo con el Button asChild y el
                as="button" renderizaba un <button> sin href ni form, así que el
                click no mandaba el DELETE. router.delete sí, y es el patrón que
                usan los demás deletes de la app. flushAll limpia la caché de
                páginas para que la sesión cerrada no quede visible al volver
                atrás. */}
            <button
              type="button"
              onClick={() => {
                router.delete(sessions.destroy(auth.session.id), {
                  onSuccess: () => router.flushAll(),
                })
              }}
            >
              <LogOut className="size-4" aria-hidden="true" />
              {t(`${page}.sign_out`)}
            </button>
          </Button>
        }
      >
        <div className="flex items-center gap-3 border-b pb-6">
          <Avatar size="lg">
            <AvatarImage src={auth.user.avatar} alt={auth.user.name} />
            <AvatarFallback>{getInitials(auth.user.name)}</AvatarFallback>
          </Avatar>
          <div className="min-w-0">
            <p className="truncate text-base font-semibold">{auth.user.name}</p>
            <p className="text-muted-foreground truncate text-sm">
              {auth.user.email}
            </p>
          </div>
        </div>

        <section aria-labelledby="benefit-title" className="grid gap-3">
          <BenefitSummaryCard
            title={t(`${page}.benefit`)}
            titleId="benefit-title"
            summary={benefit_summary}
            empty={t(`${page}.no_benefit`)}
          />

          {benefit != null && (
            <dl className="border-t">
              <Row
                label={t(`${page}.monthly_limit`)}
                value={t(`${page}.meals`, { count: benefit.monthly_limit })}
              />
              <Row
                label={t(`${page}.monthly_remaining`)}
                value={t(`${page}.meals`, { count: benefit.monthly_remaining })}
              />
              {benefit.max_price != null && (
                <Row
                  label={t(`${page}.max_price`)}
                  value={formatMoney(benefit.max_price)}
                />
              )}
              {benefit.due_date != null && (
                <Row label={t(`${page}.due_date`)} value={benefit.due_date} />
              )}
            </dl>
          )}
        </section>
      </PageContainer>

      <ConsumerMobileNav />
    </AppLayout>
  )
}
