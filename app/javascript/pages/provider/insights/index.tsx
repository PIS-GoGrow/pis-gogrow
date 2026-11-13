import { Head, Link, router } from "@inertiajs/react"
import { ChevronLeft, Star, Utensils } from "lucide-react"
import { type ReactNode, useState } from "react"
import { useTranslation } from "react-i18next"

import { DateRangePicker } from "@/components/date-picker"
import PageContainer from "@/components/page-container"
import AiInsightCard from "@/components/provider/ai-insight-card"
import InsightsMetrics from "@/components/provider/insights-metrics"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import {
  Empty,
  EmptyHeader,
  EmptyMedia,
  EmptyTitle,
} from "@/components/ui/empty"
import { Label } from "@/components/ui/label"
import { Spinner } from "@/components/ui/spinner"
import { useReviewInsightsConclusions } from "@/hooks/use-review-insights-conclusions"
import AppLayout from "@/layouts/app-layout"
import { formatShortDate } from "@/lib/dates"
import { providerDashboard, providerInsights } from "@/routes"
import type { BreadcrumbItem, ProviderInsightsIndex } from "@/types"

const page = "pages.provider_insights.index"

export default function ProviderInsights(props: ProviderInsightsIndex) {
  return <ProviderInsightsPeriod key={`${props.from}:${props.to}`} {...props} />
}

function ProviderInsightsPeriod({
  from,
  to,
  default_from,
  default_to,
  min,
  max,
  month_label,
  presets,
  orders_count,
  dishes_count,
  average_rating,
  top_dishes,
  top_rated_dishes,
}: ProviderInsightsIndex) {
  const { t } = useTranslation()
  const { conclusion, error, generating, generate, cancel } =
    useReviewInsightsConclusions(from, to)
  const [navigating, setNavigating] = useState(false)

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.provider_dashboard.index.title"),
      href: providerDashboard.index().url,
    },
    { title: t(`${page}.title`), href: providerInsights.index().url },
  ]

  function selectRange(desde: string, hasta: string) {
    if (desde === from && hasta === to) return
    cancel()
    setNavigating(true)
    const isDefault = desde === default_from && hasta === default_to

    router.get(
      providerInsights.index({ query: isDefault ? {} : { desde, hasta } }).url,
      {},
      { preserveScroll: true, onFinish: () => setNavigating(false) },
    )
  }

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t(`${page}.title`)} />

      <PageContainer
        centered
        title={t(`${page}.title`)}
        back={
          <Button asChild variant="ghost" size="icon" className="-ml-2.5">
            <Link
              href={providerDashboard.index()}
              aria-label={t(`${page}.back`)}
            >
              <ChevronLeft className="size-5" aria-hidden="true" />
            </Link>
          </Button>
        }
      >
        <div className="flex items-center justify-between gap-4">
          <Label
            htmlFor="insights-period"
            className="text-muted-foreground font-normal"
          >
            {t(`${page}.period`)}
          </Label>
          <DateRangePicker
            id="insights-period"
            from={from}
            to={to}
            min={min}
            max={max}
            label={month_label}
            commitOnComplete
            presets={presets.map((preset) => ({
              ...preset,
              label: t(`${page}.presets.${preset.key}`),
            }))}
            className="bg-card dark:bg-card text-muted-foreground dark:border-border hover:text-muted-foreground h-9 min-w-0 gap-1.5 rounded-lg border-[#E8E8E8] px-3 shadow-none"
            onChange={selectRange}
          />
        </div>

        <InsightsMetrics
          orders={orders_count}
          dishes={dishes_count}
          rating={average_rating}
        />

        <AiInsightCard generated={conclusion !== null}>
          <div aria-live="polite" aria-atomic="true" className="space-y-3">
            {conclusion ? (
              <>
                <p className="leading-relaxed whitespace-pre-wrap">
                  {conclusion.text}
                </p>
                <p className="text-muted-foreground text-xs">
                  {t(`${page}.analysis_period`, {
                    from: formatShortDate(conclusion.period.from),
                    to: formatShortDate(conclusion.period.to),
                  })}
                  {" · "}
                  {t(`${page}.reviews_considered`, {
                    count: conclusion.review_count,
                  })}
                </p>
              </>
            ) : (
              <p>{t(`${page}.ai_initial`)}</p>
            )}
            {error && (
              <Alert variant="destructive">
                <AlertDescription>
                  {t(`${page}.ai_errors.${error}`)}
                </AlertDescription>
              </Alert>
            )}
          </div>
          <Button
            type="button"
            disabled={generating || navigating}
            onClick={() => void generate()}
            className="w-full sm:w-auto"
          >
            {generating && <Spinner aria-hidden="true" />}
            {t(`${page}.${generating ? "ai_generating" : "ai_generate"}`)}
          </Button>
        </AiInsightCard>

        <div className="grid gap-6 pt-2 lg:grid-cols-2">
          <InsightsSection
            id="top-dishes-title"
            title={t(`${page}.top_dishes`)}
            empty={
              <InsightsEmpty
                icon={<Utensils aria-hidden="true" />}
                title={t(`${page}.empty_orders`)}
              />
            }
            rows={top_dishes.map((dish) => ({
              id: dish.id,
              name: dish.name,
              value: t(`${page}.orders_count`, { count: dish.orders_count }),
            }))}
          />
          <InsightsSection
            id="top-rated-dishes-title"
            title={t(`${page}.top_rated_dishes`)}
            empty={
              <InsightsEmpty
                icon={<Star aria-hidden="true" />}
                title={t(`${page}.empty_reviews`)}
              />
            }
            rows={top_rated_dishes.map((dish) => ({
              id: dish.id,
              name: dish.name,
              value: (
                <span className="flex items-center gap-1">
                  {dish.rating}
                  <Star className="size-4 fill-current" aria-hidden="true" />
                </span>
              ),
            }))}
          />
        </div>
      </PageContainer>
    </AppLayout>
  )
}

function InsightsSection({
  id,
  title,
  rows,
  empty,
}: {
  id: string
  title: string
  rows: { id: number; name: string; value: ReactNode }[]
  empty: ReactNode
}) {
  return (
    <section className="space-y-3" aria-labelledby={id}>
      <h3 id={id} className="text-lg font-semibold">
        {title}
      </h3>
      {rows.length === 0 ? (
        empty
      ) : (
        <Card className="dark:border-border gap-0 rounded-lg border-[#E8E8E8] py-0 shadow-none">
          <ul className="divide-y px-4">
            {rows.map((row) => (
              <li
                key={row.id}
                className="flex items-center justify-between gap-4 py-3"
              >
                <span className="min-w-0 truncate">{row.name}</span>
                <span className="shrink-0">{row.value}</span>
              </li>
            ))}
          </ul>
        </Card>
      )}
    </section>
  )
}

function InsightsEmpty({ icon, title }: { icon: ReactNode; title: string }) {
  return (
    <Empty className="border">
      <EmptyHeader>
        <EmptyMedia variant="icon">{icon}</EmptyMedia>
        <EmptyTitle>{title}</EmptyTitle>
      </EmptyHeader>
    </Empty>
  )
}
