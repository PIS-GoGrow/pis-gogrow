import { Head, Link } from "@inertiajs/react"
import { ArrowLeft, CircleCheck, TriangleAlert } from "lucide-react"
import { useTranslation } from "react-i18next"

import ConsumerYearHistory from "@/components/admin/consumer-year-history"
import ConsumptionStatusBadge from "@/components/admin/consumption-status-badge"
import BenefitSummaryCard from "@/components/benefit-summary-card"
import DebtReminderDialog from "@/components/collections/debt-reminder-dialog"
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
import { Progress } from "@/components/ui/progress"
import { Separator } from "@/components/ui/separator"
import { useFormatters } from "@/hooks/use-formatters"
import { useInitials } from "@/hooks/use-initials"
import AppLayout from "@/layouts/app-layout"
import { cn } from "@/lib/utils"
import { adminConsumers, adminDebtReminders } from "@/routes"
import type { AdminConsumersShow, BreadcrumbItem } from "@/types"

const page = "pages.admin.consumers.show"

export default function Show({
  consumer,
  summary,
  benefit_summary,
  months,
  debt_reminder,
}: AdminConsumersShow) {
  const { t } = useTranslation()
  const { formatMoney } = useFormatters()
  const getInitials = useInitials()

  const progress =
    summary.meals_limit > 0
      ? Math.min(100, (summary.meals_used / summary.meals_limit) * 100)
      : 0

  // El recordatorio solo aparece cuando hay algo que decir: se puede mandar, hay
  // que esperar, o se agotaron los envíos.
  const showReminder =
    debt_reminder.eligible ||
    debt_reminder.blocked_reason === "cooldown" ||
    debt_reminder.blocked_reason === "limit_reached"

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
        <div className="grid gap-4 lg:grid-cols-2">
          <Card className="gap-4 py-4">
            <CardContent className="grid gap-4 px-4">
              <div className="flex items-center gap-3">
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
              </div>

              {showReminder && (
                <div className="grid gap-2">
                  <DebtReminderDialog
                    action={adminDebtReminders.create(consumer.id).url}
                    eligible={debt_reminder.eligible}
                    employeeName={consumer.name}
                    amount={debt_reminder.amount}
                    translationKey={`${page}.reminder`}
                  />

                  {debt_reminder.blocked_reason === "cooldown" && (
                    <p className="flex items-center gap-2 text-sm text-emerald-600 dark:text-emerald-400">
                      <CircleCheck className="size-4" aria-hidden="true" />
                      {t(`${page}.reminder.next_available`, {
                        date: debt_reminder.next_available_at,
                      })}
                    </p>
                  )}

                  {debt_reminder.blocked_reason === "limit_reached" && (
                    <p className="text-muted-foreground flex items-center gap-2 text-sm">
                      <TriangleAlert className="size-4" aria-hidden="true" />
                      {t(`${page}.reminder.limit_reached`)}
                    </p>
                  )}
                </div>
              )}
            </CardContent>
          </Card>

          <div></div>

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

        <ConsumerYearHistory
          key={consumer.id}
          months={months}
          companyName={consumer.company_name}
        />
      </PageContainer>
    </AppLayout>
  )
}
