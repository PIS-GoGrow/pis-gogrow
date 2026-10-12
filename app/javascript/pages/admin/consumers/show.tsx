import { Head, Link } from "@inertiajs/react"
import { ArrowLeft, ChevronRight, Users } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import ConsumerMonthSheet from "@/components/admin/consumer-month-sheet"
import ConsumptionStatusBadge from "@/components/admin/consumption-status-badge"
import BenefitSummaryCard from "@/components/benefit-summary-card"
import HeadingSmall from "@/components/heading-small"
import ListItemCard from "@/components/list-item-card"
import PageContainer from "@/components/page-container"
import { Avatar, AvatarFallback } from "@/components/ui/avatar"
import { Badge } from "@/components/ui/badge"
import { buttonVariants } from "@/components/ui/button"
import {
  Card,
  CardAction,
  CardContent,
  CardDescription,
  CardHeader,
} from "@/components/ui/card"
import {
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyMedia,
  EmptyTitle,
} from "@/components/ui/empty"
import { Progress } from "@/components/ui/progress"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { Separator } from "@/components/ui/separator"
import { useFormatters } from "@/hooks/use-formatters"
import { useInitials } from "@/hooks/use-initials"
import AppLayout from "@/layouts/app-layout"
import { cn } from "@/lib/utils"
import { adminConsumers } from "@/routes"
import type { AdminConsumersShow, BreadcrumbItem } from "@/types"

const page = "pages.admin.consumers.show"

export default function Show({
  consumer,
  summary,
  benefit_summary,
  months,
}: AdminConsumersShow) {
  const { t } = useTranslation()
  const { formatMoney } = useFormatters()
  const getInitials = useInitials()

  const years = [...new Set(months.map((month) => month.year))]
  const [year, setYear] = useState(String(years[0] ?? ""))
  const [selectedKey, setSelectedKey] = useState<string | null>(null)
  const [sheetOpen, setSheetOpen] = useState(false)

  const visibleMonths = months.filter((month) => String(month.year) === year)
  const selectedMonth = months.find((month) => month.key === selectedKey)

  const progress =
    summary.meals_limit > 0
      ? Math.min(100, (summary.meals_used / summary.meals_limit) * 100)
      : 0

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.admin.consumers.index.title"),
      href: adminConsumers.index().url,
    },
    { title: consumer.name, href: adminConsumers.show(consumer.id).url },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t(`${page}.title`)} />

      <PageContainer
        title={t(`${page}.title`)}
        back={
          <Link
            href={adminConsumers.index()}
            className={cn(
              buttonVariants({ variant: "ghost", size: "sm" }),
              "-ml-2.5",
            )}
          >
            <ArrowLeft aria-hidden="true" />
            {t(`${page}.back`)}
          </Link>
        }
      >
        <Card className="gap-4 py-4">
          <CardContent className="flex items-center gap-3 px-4">
            <Avatar size="lg">
              <AvatarFallback className="text-foreground text-xs font-semibold">
                {getInitials(consumer.name)}
              </AvatarFallback>
            </Avatar>
            <div className="min-w-0 flex-1">
              <p className="truncate font-semibold">{consumer.name}</p>
              <p className="text-muted-foreground truncate text-sm">
                {consumer.email}
              </p>
            </div>
            <ConsumptionStatusBadge status={summary.status} />
          </CardContent>
        </Card>

        <div className="grid gap-4 md:grid-cols-2">
          <Card className="bg-muted/50 gap-3 py-4">
            <CardHeader className="px-4">
              <CardDescription>{t(`${page}.consumption`)}</CardDescription>
              <CardAction>
                <Badge variant="secondary">{t(`${page}.this_month`)}</Badge>
              </CardAction>
            </CardHeader>
            <CardContent className="grid gap-3 px-4">
              <p className="flex flex-wrap items-baseline gap-x-2">
                <strong className="text-2xl">
                  {formatMoney(summary.amount)}
                </strong>
                <span className="text-muted-foreground text-sm">
                  {"| "}
                  {summary.meals_limit > 0
                    ? t(`${page}.meals_used`, {
                        used: summary.meals_used,
                        limit: summary.meals_limit,
                      })
                    : t(`${page}.meals_used_no_limit`, {
                        count: summary.meals_used,
                      })}
                </span>
              </p>

              {summary.meals_limit > 0 && (
                <Progress value={progress} className="h-2" />
              )}

              {summary.providers.length > 0 && (
                <>
                  <Separator />
                  <dl className="grid gap-1 text-sm">
                    {summary.providers.map((provider) => (
                      <div
                        key={provider.name}
                        className="flex items-baseline justify-between gap-4"
                      >
                        <dt className="text-muted-foreground">
                          {provider.name}
                        </dt>
                        <dd className="font-medium">
                          {t(`${page}.meals`, { count: provider.meals })}
                        </dd>
                      </div>
                    ))}
                  </dl>
                </>
              )}
            </CardContent>
          </Card>

          <BenefitSummaryCard
            title={t(`${page}.benefit`)}
            summary={benefit_summary}
            empty={t(`${page}.benefit_none`)}
          />
        </div>

        <div className="flex items-center justify-between gap-4">
          <HeadingSmall title={t(`${page}.history`)} />

          {years.length > 1 && (
            <Select value={year} onValueChange={setYear}>
              <SelectTrigger size="sm" aria-label={t(`${page}.year_label`)}>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {years.map((option) => (
                  <SelectItem key={option} value={String(option)}>
                    {option}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          )}
        </div>

        {months.length === 0 ? (
          <Empty className="border">
            <EmptyHeader>
              <EmptyMedia variant="icon">
                <Users aria-hidden="true" />
              </EmptyMedia>
              <EmptyTitle>{t(`${page}.history_empty_title`)}</EmptyTitle>
              <EmptyDescription>
                {t(`${page}.history_empty_description`)}
              </EmptyDescription>
            </EmptyHeader>
          </Empty>
        ) : (
          <div className="grid gap-4 md:grid-cols-2">
            {visibleMonths.map((month) => (
              <ListItemCard
                key={month.key}
                className="hover:bg-accent/40 focus-within:ring-ring/50 relative transition-colors focus-within:ring-[3px]"
              >
                <CardContent>
                  <button
                    type="button"
                    onClick={() => {
                      setSelectedKey(month.key)
                      setSheetOpen(true)
                    }}
                    aria-label={t(`${page}.view_month`, { month: month.label })}
                    className="flex w-full items-center gap-3 text-left outline-none after:absolute after:inset-0"
                  >
                    <span className="flex-1 font-medium">{month.label}</span>
                    <span className="font-semibold">
                      {formatMoney(month.amount)}
                    </span>
                    <ConsumptionStatusBadge status={month.status} />
                    <ChevronRight
                      className="text-muted-foreground size-4 shrink-0"
                      aria-hidden="true"
                    />
                  </button>
                </CardContent>
              </ListItemCard>
            ))}
          </div>
        )}

        <ConsumerMonthSheet
          month={selectedMonth}
          companyName={consumer.company_name}
          open={sheetOpen}
          onClose={() => setSheetOpen(false)}
        />
      </PageContainer>
    </AppLayout>
  )
}
