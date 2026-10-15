import { SlidersHorizontal } from "lucide-react"
import { useMemo, useState } from "react"
import { useTranslation } from "react-i18next"

import {
  AdaptableDialog,
  AdaptableDialogClose,
  AdaptableDialogContent,
  AdaptableDialogDescription,
  AdaptableDialogFooter,
  AdaptableDialogHeader,
  AdaptableDialogTitle,
  AdaptableDialogTrigger,
} from "@/components/adaptable-dialog"
import ConsumptionDayList from "@/components/collections/consumption-day-list"
import { Button } from "@/components/ui/button"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuRadioGroup,
  DropdownMenuRadioItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { useFormatters } from "@/hooks/use-formatters"
import type { ProviderCollectionsIndex } from "@/types"

type SalesDetail = ProviderCollectionsIndex["sales_detail"]
type SalesOrder = SalesDetail["days"][number]["orders"][number]

interface SalesDetailDialogProps {
  detail: SalesDetail
}

const page = "pages.provider_collections.index"

export default function SalesDetailDialog({ detail }: SalesDetailDialogProps) {
  const { t } = useTranslation()
  const { formatMoney } = useFormatters()
  const [client, setClient] = useState("all")

  const selectedClient = detail.clients.find(
    (option) => String(option.id) === client,
  )
  const visibleClients = selectedClient ? [selectedClient] : detail.clients

  const days = useMemo(
    () =>
      detail.days
        .map((day) => ({
          ...day,
          orders: selectedClient
            ? day.orders.filter(
                (order) => order.client_id === selectedClient.id,
              )
            : day.orders,
        }))
        .filter((day) => day.orders.length > 0),
    [detail.days, selectedClient],
  )

  return (
    <AdaptableDialog>
      <AdaptableDialogTrigger asChild>
        <Button type="button" className="w-full">
          {t(`${page}.view_consumption_detail`)}
        </Button>
      </AdaptableDialogTrigger>

      <AdaptableDialogContent
        showCloseButton={false}
        className="gap-0 p-0 sm:max-w-2xl"
      >
        <AdaptableDialogHeader className="border-b p-4 text-left">
          <AdaptableDialogTitle>
            {t(`${page}.consumption_detail_title`, { month: detail.month })}
          </AdaptableDialogTitle>
          <AdaptableDialogDescription className="sr-only">
            {t(`${page}.consumption_detail_description`)}
          </AdaptableDialogDescription>
        </AdaptableDialogHeader>

        <div className="flex items-center justify-between gap-2 px-4 py-3">
          <p className="text-sm">
            {t(`${page}.clients`)}{" "}
            <span className="text-muted-foreground">
              {selectedClient?.name ?? t(`${page}.all_clients`)}
            </span>
          </p>
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button
                variant="outline"
                size="icon"
                className="rounded-full"
                aria-label={t(`${page}.filter_clients`)}
              >
                <SlidersHorizontal aria-hidden="true" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuRadioGroup value={client} onValueChange={setClient}>
                <DropdownMenuRadioItem value="all">
                  {t(`${page}.all_clients`)}
                </DropdownMenuRadioItem>
                {detail.clients.map((option) => (
                  <DropdownMenuRadioItem
                    key={option.id}
                    value={String(option.id)}
                  >
                    {option.name}
                  </DropdownMenuRadioItem>
                ))}
              </DropdownMenuRadioGroup>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>

        <div className="max-h-[60dvh] overflow-y-auto px-4">
          <ConsumptionDayList
            days={days}
            mealsOf={(order: SalesOrder) => order.meals}
            amountOf={(order: SalesOrder) => order.amount}
            formatAmount={formatMoney}
            emptyLabel={t(`${page}.consumption_empty`)}
          >
            {(orders) => (
              <Table className="min-w-[35rem] table-fixed">
                <TableHeader className="bg-muted/70">
                  <TableRow>
                    <TableHead className="w-[34%]">
                      {t(`${page}.consumption_name`)}
                    </TableHead>
                    <TableHead className="w-[28%]">
                      {t(`${page}.consumption_company`)}
                    </TableHead>
                    <TableHead className="w-[16%] text-center">
                      {t(`${page}.consumption_quantity`)}
                    </TableHead>
                    <TableHead className="w-[22%] text-right">
                      {t(`${page}.consumption_amount_column`)}
                    </TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {orders.map((order) => (
                    <TableRow key={order.id}>
                      <TableCell className="wrap-anywhere whitespace-normal">
                        {order.consumer_name}
                      </TableCell>
                      <TableCell className="wrap-anywhere whitespace-normal">
                        {order.client_name}
                      </TableCell>
                      <TableCell className="text-center">
                        {order.meals}
                      </TableCell>
                      <TableCell className="text-right">
                        {formatMoney(order.amount)}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            )}
          </ConsumptionDayList>
        </div>

        <AdaptableDialogFooter className="p-4 sm:flex-col">
          <dl className="grid w-full gap-2 text-sm">
            <div className="flex justify-between gap-3">
              <dt>{t(`${page}.subtotal`)}</dt>
              <dd>
                {formatMoney(
                  visibleClients.reduce((sum, item) => sum + item.subtotal, 0),
                )}
              </dd>
            </div>
            <div className="flex justify-between gap-3">
              <dt>{t("pages.provider_collections.index.subsidy_vat")}</dt>
              <dd>
                {formatMoney(
                  visibleClients.reduce(
                    (sum, item) => sum + item.vat_amount,
                    0,
                  ),
                )}
              </dd>
            </div>
            <div className="flex justify-between gap-3 font-semibold">
              <dt>
                {t(
                  "pages.provider_collections.group.detail_dialog.total_label",
                )}
              </dt>
              <dd>
                {formatMoney(
                  visibleClients.reduce(
                    (sum, item) => sum + item.payable_amount,
                    0,
                  ),
                )}
              </dd>
            </div>
          </dl>
          <AdaptableDialogClose asChild>
            <Button className="w-full">
              {t(`${page}.close_consumption_detail`)}
            </Button>
          </AdaptableDialogClose>
        </AdaptableDialogFooter>
      </AdaptableDialogContent>
    </AdaptableDialog>
  )
}
