import { ChevronRight, Users } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import ConsumerMonthSheet from "@/components/admin/consumer-month-sheet"
import ConsumptionStatusBadge from "@/components/admin/consumption-status-badge"
import HeadingSmall from "@/components/heading-small"
import { Card } from "@/components/ui/card"
import {
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyMedia,
  EmptyTitle,
} from "@/components/ui/empty"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { useFormatters } from "@/hooks/use-formatters"
import type { AdminConsumerMonth } from "@/types"

interface ConsumerYearHistoryProps {
  months: AdminConsumerMonth[]
  companyName: string
}

const page = "pages.admin.consumers.show"

export default function ConsumerYearHistory({
  months,
  companyName,
}: ConsumerYearHistoryProps) {
  const { t } = useTranslation()
  const { formatMoney } = useFormatters()
  const years = [...new Set(months.map((month) => month.year))]
  const [year, setYear] = useState(String(years[0] ?? ""))
  const [selectedKey, setSelectedKey] = useState<string | null>(null)
  const [sheetOpen, setSheetOpen] = useState(false)

  const visibleMonths = months.filter((month) => String(month.year) === year)
  const neverOrdered = months.every((month) => month.orders.length === 0)
  const selectedMonth = months.find((month) => month.key === selectedKey)

  return (
    <>
      <div className="flex items-center justify-between gap-4">
        <HeadingSmall title={t(`${page}.history`)} />

        {!neverOrdered && (
          <Select
            value={year}
            onValueChange={(value) => {
              setYear(value)
              setSelectedKey(null)
              setSheetOpen(false)
            }}
          >
            <SelectTrigger size="sm" aria-label={t(`${page}.year_label`)}>
              <SelectValue />
            </SelectTrigger>
            <SelectContent align="end">
              {years.map((option) => (
                <SelectItem key={option} value={String(option)}>
                  {option}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        )}
      </div>

      {neverOrdered ? (
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
        <Card className="gap-0 divide-y py-0">
          {visibleMonths.map((month) => (
            <button
              key={month.key}
              type="button"
              onClick={() => {
                setSelectedKey(month.key)
                setSheetOpen(true)
              }}
              aria-label={t(`${page}.view_month`, {
                month: month.label,
              })}
              className="hover:bg-accent/40 focus-visible:ring-ring/50 flex w-full items-center gap-3 px-4 py-3 text-left transition-colors outline-none focus-visible:ring-[3px]"
            >
              <span className="flex-1 font-medium">{month.name}</span>
              <span className="font-semibold">{formatMoney(month.amount)}</span>
              <ConsumptionStatusBadge status={month.status} />
              <ChevronRight
                className="text-muted-foreground size-4 shrink-0"
                aria-hidden="true"
              />
            </button>
          ))}
        </Card>
      )}

      <ConsumerMonthSheet
        key={selectedMonth?.key ?? "closed"}
        month={selectedMonth}
        companyName={companyName}
        open={sheetOpen}
        onClose={() => setSheetOpen(false)}
      />
    </>
  )
}
