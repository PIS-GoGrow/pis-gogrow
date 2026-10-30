import { Head, Link, router } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import BenefitUsageCollapsibleCard from "@/components/admin/benefit-usage-collapsible-card"
import BenefitUsageMetrics from "@/components/admin/benefit-usage-metrics"
import MonthSelect from "@/components/admin/month-select"
import PageContainer from "@/components/page-container"
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { Button } from "@/components/ui/button"
import { Skeleton } from "@/components/ui/skeleton"
import { Spinner } from "@/components/ui/spinner"
import { useBenefitUsage } from "@/hooks/use-benefit-usage"
import AppLayout from "@/layouts/app-layout"
import { formatBenefitMonth } from "@/lib/benefit-usage"
import { adminBenefitUsage, adminDashboard } from "@/routes"
import type { AdminBenefitUsageAnalysis } from "@/types/serializers"

export default function Analysis(props: AdminBenefitUsageAnalysis) {
  return <AnalysisMonth key={props.month} {...props} />
}

function AnalysisMonth({
  month,
  current_month,
  months,
}: AdminBenefitUsageAnalysis) {
  const { t } = useTranslation()
  const usage = useBenefitUsage(month)
  const [navigating, setNavigating] = useState(false)
  const p = "benefit_usage.ui"

  function selectMonth(value: string) {
    if (value === month) return
    usage.cancelSummary()
    setNavigating(true)
    router.get(
      adminBenefitUsage.analysis({ query: { month: value } }).url,
      {},
      {
        preserveScroll: true,
        onFinish: () => setNavigating(false),
      },
    )
  }

  const aiSummary = (
    <BenefitUsageCollapsibleCard
      title={t(`${p}.ai_title`)}
      defaultOpen
      className="border-violet-300 bg-violet-50 text-violet-950 dark:border-violet-900 dark:bg-violet-950/30 dark:text-violet-100"
      contentClassName="space-y-4"
    >
      <p className="text-sm leading-relaxed text-violet-900 dark:text-violet-200">
        {t(`${p}.ai_description`)}
      </p>
      <Button
        disabled={!usage.stats || usage.generating || navigating}
        onClick={() => void usage.generate()}
        className="w-full sm:w-auto"
      >
        {usage.generating && <Spinner aria-hidden="true" />}
        {t(`${p}.${usage.generating ? "generating" : "generate"}`)}
      </Button>
      <div aria-live="polite" aria-atomic="true">
        {usage.summaryError && (
          <Alert variant="destructive">
            <AlertDescription>
              {t(`${p}.errors.${usage.summaryError}`)}
            </AlertDescription>
          </Alert>
        )}
        {usage.summary !== null && (
          <div className="space-y-4 border-t border-violet-200 pt-5 dark:border-violet-800">
            <p className="text-xs leading-relaxed text-violet-800 dark:text-violet-200">
              {t(`${p}.ai_notice`)}
            </p>
            <p className="text-sm leading-relaxed whitespace-pre-wrap">
              {usage.summary}
            </p>
          </div>
        )}
      </div>
    </BenefitUsageCollapsibleCard>
  )

  return (
    <AppLayout>
      <Head title={t(`${p}.title`)} />
      <PageContainer
        title={t(`${p}.title`)}
        description={formatBenefitMonth(month)}
        back={
          <Button asChild variant="ghost" size="sm">
            <Link href={adminDashboard.index({ query: { month } }).url}>
              <ArrowLeft aria-hidden="true" />
              {t(`${p}.back`)}
            </Link>
          </Button>
        }
        actions={
          <MonthSelect
            value={month}
            currentMonth={current_month}
            months={months}
            onValueChange={selectMonth}
            label={t(`${p}.month_label`)}
            compactMenu
            className="border-border bg-muted text-foreground hover:bg-accent hover:text-accent-foreground focus-visible:border-ring focus-visible:ring-ring/50 dark:bg-muted dark:hover:bg-accent [&_svg]:text-foreground border border-solid shadow-xs [&_svg]:opacity-100"
          />
        }
      >
        {aiSummary}

        {navigating || (!usage.stats && !usage.error) ? (
          <div
            role="status"
            aria-label={t(`${p}.loading`)}
            className="space-y-4"
          >
            <span className="sr-only">{t(`${p}.loading`)}</span>
            <Skeleton className="h-64 w-full rounded-lg" />
            <Skeleton className="h-40 w-full rounded-lg" />
          </div>
        ) : usage.error ? (
          <Alert variant="destructive">
            <AlertTitle>{t(`${p}.load_error`)}</AlertTitle>
            <AlertDescription>
              <p>{t(`${p}.load_error_detail`)}</p>
              <Button variant="outline" onClick={usage.retry}>
                {t(`${p}.retry`)}
              </Button>
            </AlertDescription>
          </Alert>
        ) : usage.stats ? (
          <BenefitUsageMetrics stats={usage.stats} />
        ) : null}
      </PageContainer>
    </AppLayout>
  )
}
