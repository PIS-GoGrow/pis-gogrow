import { ChevronDown, SlidersHorizontal } from "lucide-react"
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
import { Button } from "@/components/ui/button"
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible"
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

  const mealsOf = (orders: SalesOrder[]) =>
    orders.reduce((total, order) => total + order.meals, 0)

  const amountOf = (orders: SalesOrder[]) =>
    orders.reduce((total, order) => total + order.amount, 0)

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
          {days.length === 0 ? (
            <p className="text-muted-foreground py-8 text-center text-sm">
              {t(`${page}.consumption_empty`)}
            </p>
          ) : (
            <div className="divide-y rounded-xl border px-4">
              {days.map((day, index) => (
                <Collapsible key={day.date} defaultOpen={index === 0}>
                  <CollapsibleTrigger asChild>
                    <button
                      type="button"
                      className="group flex w-full items-center justify-between gap-3 py-4 text-left text-sm font-medium"
                    >
                      <span>
                        {t(`${page}.consumption_day`, { date: day.date })} |{" "}
                        {t(`${page}.consumption_meals`, {
                          count: mealsOf(day.orders),
                        })}{" "}
                        |{" "}
                        {t(`${page}.consumption_amount`, {
                          amount: formatMoney(amountOf(day.orders)),
                        })}
                      </span>
                      <ChevronDown
                        aria-hidden="true"
                        className="size-4 shrink-0 transition-transform group-data-[state=open]:rotate-180"
                      />
                    </button>
                  </CollapsibleTrigger>
                  <CollapsibleContent className="pb-2">
                    <div className="overflow-hidden rounded-xl border">
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
                          {day.orders.map((order) => (
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
                    </div>
                  </CollapsibleContent>
                </Collapsible>
              ))}
            </div>
          )}
        </div>

        <AdaptableDialogFooter className="p-4">
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
