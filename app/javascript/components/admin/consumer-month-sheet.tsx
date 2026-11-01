import { Download, SearchX, SlidersHorizontal } from "lucide-react"
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
import ConsumptionStatusBadge from "@/components/admin/consumption-status-badge"
import { Button } from "@/components/ui/button"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuRadioGroup,
  DropdownMenuRadioItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
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
  const [providerId, setProviderId] = useState<number | null>(null)
  const filtered = month
    ? filterConsumerHistory(month, {
        ...emptyConsumerHistoryFilters(),
        providers: new Set(providerId === null ? [] : [providerId]),
      })
    : null
  const providerName = month?.providers.find(
    (provider) => provider.id === providerId,
  )?.name

  return (
    <AdaptableDialog
      desktopVariant="sheet"
      open={open}
      onOpenChange={(isOpen) => !isOpen && onClose()}
    >
      <AdaptableDialogContent className="max-w-xl!" showCloseButton={false}>
        {month && filtered && (
          <>
            <AdaptableDialogHeader>
              <AdaptableDialogTitle>
                {t(`${page}.month_detail`, { month: month.label })}
              </AdaptableDialogTitle>
              <AdaptableDialogDescription className="sr-only">
                {t(`${page}.month_detail_description`)}
              </AdaptableDialogDescription>
            </AdaptableDialogHeader>

            <div className="grid gap-4 px-4">
              <div className="flex items-center justify-between gap-3">
                <p className="min-w-0 text-sm">
                  {t(`${page}.filters.providers`)}{" "}
                  <span className="text-muted-foreground">
                    {providerName ?? t(`${page}.filters.all_providers`)}
                  </span>
                </p>
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <Button
                      variant="outline"
                      size="icon"
                      className="rounded-full"
                      aria-label={t(`${page}.filters.open`)}
                    >
                      <SlidersHorizontal aria-hidden="true" />
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end">
                    <DropdownMenuRadioGroup
                      value={String(providerId ?? "all")}
                      onValueChange={(value) =>
                        setProviderId(value === "all" ? null : Number(value))
                      }
                    >
                      <DropdownMenuRadioItem value="all">
                        {t(`${page}.filters.all_providers`)}
                      </DropdownMenuRadioItem>
                      {month.providers.map((provider) => (
                        <DropdownMenuRadioItem
                          key={provider.id}
                          value={String(provider.id)}
                        >
                          {provider.name}
                        </DropdownMenuRadioItem>
                      ))}
                    </DropdownMenuRadioGroup>
                  </DropdownMenuContent>
                </DropdownMenu>
              </div>

              {filtered.orders.length === 0 ? (
                <Empty className="border py-8">
                  <EmptyHeader>
                    <EmptyMedia variant="icon">
                      <SearchX aria-hidden="true" />
                    </EmptyMedia>
                    <EmptyTitle>
                      {providerId === null
                        ? t(`${page}.orders_empty_title`)
                        : t(`${page}.filters.empty_title`)}
                    </EmptyTitle>
                    <EmptyDescription>
                      {providerId === null
                        ? t(`${page}.orders_empty`)
                        : t(`${page}.filters.empty_description`)}
                    </EmptyDescription>
                  </EmptyHeader>
                </Empty>
              ) : (
                <div className="overflow-hidden rounded-lg border">
                  <Table className="table-fixed">
                    <TableHeader className="bg-muted/70">
                      <TableRow>
                        <TableHead className="w-12">
                          {t(`${page}.date`)}
                        </TableHead>
                        <TableHead>{t(`${page}.provider`)}</TableHead>
                        <TableHead className="w-11 text-center">
                          {t(`${page}.quantity`)}
                        </TableHead>
                        <TableHead className="w-18 text-right">
                          {companyName}
                        </TableHead>
                        <TableHead className="w-19 text-right">
                          {t(`${page}.employee`)}
                        </TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {filtered.orders.map((order) => (
                        <TableRow key={order.id}>
                          <TableCell>{order.date}</TableCell>
                          <TableCell className="truncate">
                            {order.provider_name ?? t(`${page}.no_provider`)}
                          </TableCell>
                          <TableCell className="text-center">
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

                  <dl className="grid gap-2 border-t px-2 py-3 text-sm">
                    {filtered.providers.map((provider) => (
                      <div
                        key={provider.id}
                        className="flex items-center justify-between gap-2 border-b pb-2"
                      >
                        <dt className="min-w-0 truncate font-medium">
                          {provider.name}: {formatMoney(provider.amount)}
                        </dt>
                        <dd className="flex shrink-0 items-center gap-1">
                          <ConsumptionStatusBadge status={provider.status} />
                          {provider.receipt_url && (
                            <Button variant="ghost" size="icon-sm" asChild>
                              <a
                                href={provider.receipt_url}
                                download
                                aria-label={t(`${page}.download_receipt`, {
                                  provider: provider.name,
                                })}
                              >
                                <Download aria-hidden="true" />
                              </a>
                            </Button>
                          )}
                        </dd>
                      </div>
                    ))}
                    <div className="border-foreground/40 -mt-2 border-t pt-2 text-base font-semibold">
                      <dt className="sr-only">{t(`${page}.total_label`)}</dt>
                      <dd>
                        {t(`${page}.total`, {
                          amount: formatMoney(filtered.total),
                        })}
                      </dd>
                    </div>
                  </dl>
                </div>
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
