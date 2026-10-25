import { SearchX, X } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import {
  AdaptableDialog,
  AdaptableDialogClose,
  AdaptableDialogContent,
  AdaptableDialogDescription,
  AdaptableDialogFooter,
  AdaptableDialogHeader,
  AdaptableDialogTitle,
} from "@/components/adaptable-dialog"
import ConsumerHistoryFiltersPopover from "@/components/admin/consumer-history-filters"
import StatusBadge from "@/components/status-badge"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import {
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyMedia,
  EmptyTitle,
} from "@/components/ui/empty"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { useFormatters } from "@/hooks/use-formatters"
import {
  emptyConsumerHistoryFilters,
  filterConsumerHistory,
  hasConsumerHistoryFilters,
} from "@/lib/admin-consumer-history"
import type { AdminConsumerMonth } from "@/types"

interface ConsumerMonthAdaptableDialogProps {
  month: AdminConsumerMonth | undefined
  companyName: string
  open: boolean
  onClose: () => void
}

const page = "pages.admin.consumers.show"

export default function ConsumerMonthAdaptableDialog({
  month,
  companyName,
  open,
  onClose,
}: ConsumerMonthAdaptableDialogProps) {
  const { t } = useTranslation()
  const { formatMoney } = useFormatters()
  const [filters, setFilters] = useState(emptyConsumerHistoryFilters)
  const activeFilters = hasConsumerHistoryFilters(filters)
  const filtered = month ? filterConsumerHistory(month, filters) : null

  function removeProvider(id: number) {
    setFilters((current) => {
      const providers = new Set(current.providers)
      providers.delete(id)
      return { ...current, providers }
    })
  }

  return (
    <AdaptableDialog
      desktopVariant="sheet"
      open={open}
      onOpenChange={(isOpen) => !isOpen && onClose()}
    >
      <AdaptableDialogContent className="max-w-xl!" showCloseButton={false}>
        {month && (
          <>
            <AdaptableDialogHeader>
              <AdaptableDialogTitle>
                {t(`${page}.month_detail`, { month: month.label })}
              </AdaptableDialogTitle>
              <AdaptableDialogDescription>
                {t(`${page}.month_detail_description`)}
              </AdaptableDialogDescription>
            </AdaptableDialogHeader>

            <div className="grid gap-4 px-4">
              <div className="flex items-center justify-between gap-3">
                <p className="min-w-0 text-sm">
                  {t(`${page}.filters.providers`)}{" "}
                  <span className="text-muted-foreground">
                    {filters.providers.size === 0
                      ? t(`${page}.filters.all_providers`)
                      : month.providers
                          .filter((provider) =>
                            filters.providers.has(provider.id),
                          )
                          .map((provider) => provider.name)
                          .join(", ")}
                  </span>
                </p>
                <ConsumerHistoryFiltersPopover
                  providers={month.providers}
                  value={filters}
                  onApply={setFilters}
                />
              </div>

              {activeFilters && (
                <div className="flex flex-wrap items-center gap-2">
                  {month.providers
                    .filter((provider) => filters.providers.has(provider.id))
                    .map((provider) => (
                      <FilterChip
                        key={provider.id}
                        label={t(`${page}.filters.provider_chip`, {
                          provider: provider.name,
                        })}
                        removeLabel={t(`${page}.filters.remove_provider`, {
                          provider: provider.name,
                        })}
                        onRemove={() => removeProvider(provider.id)}
                      />
                    ))}
                  {filters.status !== "all" && (
                    <FilterChip
                      label={t(`${page}.filters.status_chip`, {
                        status: t(
                          `pages.provider_collections.statuses.${filters.status}`,
                        ),
                      })}
                      removeLabel={t(`${page}.filters.remove_status`)}
                      onRemove={() =>
                        setFilters((current) => ({
                          ...current,
                          status: "all",
                        }))
                      }
                    />
                  )}
                  {filters.subsidy !== "all" && (
                    <FilterChip
                      label={t(`${page}.filters.subsidy_chip`, {
                        subsidy: t(
                          `${page}.filters.subsidy_${filters.subsidy}`,
                        ),
                      })}
                      removeLabel={t(`${page}.filters.remove_subsidy`)}
                      onRemove={() =>
                        setFilters((current) => ({
                          ...current,
                          subsidy: "all",
                        }))
                      }
                    />
                  )}
                  <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    onClick={() => setFilters(emptyConsumerHistoryFilters())}
                  >
                    {t(`${page}.filters.clear`)}
                  </Button>
                </div>
              )}

              {filtered?.orders.length === 0 ? (
                <Empty className="border py-8">
                  <EmptyHeader>
                    <EmptyMedia variant="icon">
                      <SearchX aria-hidden="true" />
                    </EmptyMedia>
                    <EmptyTitle>
                      {activeFilters
                        ? t(`${page}.filters.empty_title`)
                        : t(`${page}.orders_empty_title`)}
                    </EmptyTitle>
                    <EmptyDescription>
                      {activeFilters
                        ? t(`${page}.filters.empty_description`)
                        : t(`${page}.orders_empty`)}
                    </EmptyDescription>
                  </EmptyHeader>
                </Empty>
              ) : (
                <div className="overflow-x-auto rounded-lg border">
                  <Table className="min-w-[34rem]">
                    <TableHeader>
                      <TableRow>
                        <TableHead>{t(`${page}.date`)}</TableHead>
                        <TableHead>{t(`${page}.provider`)}</TableHead>
                        <TableHead className="text-right">
                          {t(`${page}.quantity`)}
                        </TableHead>
                        <TableHead className="text-right">
                          {companyName}
                        </TableHead>
                        <TableHead className="text-right">
                          {t(`${page}.employee`)}
                        </TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {filtered?.orders.map((order) => (
                        <TableRow key={order.id}>
                          <TableCell>{order.date}</TableCell>
                          <TableCell>
                            {order.provider_name ?? t(`${page}.no_provider`)}
                          </TableCell>
                          <TableCell className="text-right">
                            {order.amount}
                          </TableCell>
                          <TableCell className="text-right">
                            {formatMoney(order.subsidy)}
                          </TableCell>
                          <TableCell className="text-right">
                            {formatMoney(order.charged)}
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </div>
              )}

              {filtered && filtered.orders.length > 0 && (
                <dl className="grid gap-2 text-sm">
                  {filtered.providers.map((provider) => (
                    <div
                      key={provider.id}
                      className="flex items-center justify-between gap-4 border-b pb-2"
                    >
                      <dt>
                        {provider.name}:{" "}
                        <strong>{formatMoney(provider.amount)}</strong>
                      </dt>
                      <dd>
                        <StatusBadge status={provider.status} kind="payment" />
                      </dd>
                    </div>
                  ))}
                  <div className="font-semibold">
                    <dt className="sr-only">{t(`${page}.total_label`)}</dt>
                    <dd>
                      {t(`${page}.total`, {
                        amount: formatMoney(filtered.total),
                      })}
                    </dd>
                  </div>
                </dl>
              )}
            </div>

            <AdaptableDialogFooter>
              <AdaptableDialogClose asChild>
                <Button className="w-full">{t(`${page}.close`)}</Button>
              </AdaptableDialogClose>
            </AdaptableDialogFooter>
          </>
        )}
      </AdaptableDialogContent>
    </AdaptableDialog>
  )
}

function FilterChip({
  label,
  removeLabel,
  onRemove,
}: {
  label: string
  removeLabel: string
  onRemove: () => void
}) {
  return (
    <Badge variant="secondary" className="gap-1 pr-1">
      {label}
      <Button
        type="button"
        variant="ghost"
        size="icon-xs"
        className="size-5 rounded-full"
        aria-label={removeLabel}
        onClick={onRemove}
      >
        <X aria-hidden="true" />
      </Button>
    </Badge>
  )
}
