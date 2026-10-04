import { useTranslation } from "react-i18next"

import StatusBadge from "@/components/status-badge"
import { Button } from "@/components/ui/button"
import {
  Sheet,
  SheetClose,
  SheetContent,
  SheetDescription,
  SheetFooter,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { useFormatters } from "@/hooks/use-formatters"
import type { AdminConsumerMonth } from "@/types"

interface ConsumerMonthSheetProps {
  month: AdminConsumerMonth | undefined
  companyName: string
  open: boolean
  onClose: () => void
}

const page = "pages.admin.consumers.show"

export default function ConsumerMonthSheet({
  month,
  companyName,
  open,
  onClose,
}: ConsumerMonthSheetProps) {
  const { t } = useTranslation()
  const { formatMoney } = useFormatters()

  return (
    <Sheet open={open} onOpenChange={(isOpen) => !isOpen && onClose()}>
      <SheetContent
        side="bottom"
        showCloseButton={false}
        className="mx-auto max-h-[85vh] w-full max-w-2xl overflow-y-auto rounded-t-xl"
      >
        {month && (
          <>
            <SheetHeader>
              <SheetTitle>
                {t(`${page}.month_detail`, { month: month.label })}
              </SheetTitle>
              <SheetDescription>
                {t(`${page}.month_detail_description`)}
              </SheetDescription>
            </SheetHeader>

            <div className="grid gap-4 px-4">
              {month.orders.length === 0 ? (
                <p className="text-muted-foreground text-sm">
                  {t(`${page}.orders_empty`)}
                </p>
              ) : (
                <div className="rounded-lg border">
                  <Table>
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
                      {month.orders.map((order) => (
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

              <dl className="grid gap-2 text-sm">
                {month.providers.map((provider) => (
                  <div
                    key={provider.name}
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
                <p className="font-semibold">
                  {t(`${page}.total`, { amount: formatMoney(month.amount) })}
                </p>
              </dl>
            </div>

            <SheetFooter>
              <SheetClose asChild>
                <Button className="w-full">{t(`${page}.close`)}</Button>
              </SheetClose>
            </SheetFooter>
          </>
        )}
      </SheetContent>
    </Sheet>
  )
}
