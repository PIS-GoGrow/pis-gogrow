import { useTranslation } from "react-i18next"

import { Badge } from "@/components/ui/badge"
import {
  Card,
  CardAction,
  CardContent,
  CardDescription,
  CardHeader,
} from "@/components/ui/card"
import { Separator } from "@/components/ui/separator"
import type { BenefitSummary } from "@/types"

interface Props {
  title: string
  summary: BenefitSummary | null
  empty: string
  titleId?: string
}

export default function BenefitSummaryCard({
  title,
  summary,
  empty,
  titleId,
}: Props) {
  const { t } = useTranslation()
  const rows = summary
    ? [
        ...(summary.base > 0
          ? [
              {
                name: t("components.benefit_summary.base"),
                percentage: summary.base,
              },
            ]
          : []),
        ...summary.specials,
      ]
    : []

  return (
    <Card className="bg-muted/50 gap-3 py-4">
      <CardHeader className="px-4">
        <CardDescription id={titleId} className="text-base">
          {title}
        </CardDescription>
        <CardAction>
          <Badge
            variant="secondary"
            className="bg-background text-muted-foreground rounded-full px-3 py-1 text-sm font-normal"
          >
            {summary
              ? t("components.benefit_summary.active")
              : t("components.benefit_summary.inactive")}
          </Badge>
        </CardAction>
      </CardHeader>
      <CardContent className="grid gap-3 px-4">
        {summary ? (
          <>
            <p className="flex flex-wrap items-baseline gap-x-2">
              <strong className="text-2xl">{summary.total}%</strong>
              <span className="text-lg font-semibold">
                {t("components.benefit_summary.discount")}
              </span>
            </p>
            <Separator />
            <dl className="grid gap-1 text-base">
              {rows.map((row, index) => (
                <div
                  key={`${index}-${row.name}`}
                  className="flex items-baseline justify-between gap-4"
                >
                  <dt className="text-muted-foreground">{row.name}</dt>
                  <dd className="font-semibold">{row.percentage}%</dd>
                </div>
              ))}
            </dl>
          </>
        ) : (
          <p className="text-muted-foreground text-sm">{empty}</p>
        )}
      </CardContent>
    </Card>
  )
}
