import { Star } from "lucide-react"
import { useTranslation } from "react-i18next"

import DashboardMetric from "@/components/provider/dashboard-metric"

interface InsightsMetricsProps {
  orders: number
  dishes: number
  rating?: number | null
}

const cardClassName =
  "dark:border-border dark:bg-muted rounded-xl border border-[#E8E8E8] bg-[#F5F5F5] px-2 py-4"

export default function InsightsMetrics({
  orders,
  dishes,
  rating,
}: InsightsMetricsProps) {
  const { t } = useTranslation()

  return (
    <div className="grid grid-cols-3 gap-2">
      <DashboardMetric
        className={cardClassName}
        label={t("components.insights_metrics.orders")}
        value={orders}
        valueFirst
      />
      <DashboardMetric
        className={cardClassName}
        label={t("components.insights_metrics.dishes")}
        value={dishes}
        valueFirst
      />
      <DashboardMetric
        className={cardClassName}
        icon={<Star className="size-5 fill-current" aria-hidden="true" />}
        label={t("components.insights_metrics.rating")}
        value={rating ?? "—"}
        valueFirst
      />
    </div>
  )
}
