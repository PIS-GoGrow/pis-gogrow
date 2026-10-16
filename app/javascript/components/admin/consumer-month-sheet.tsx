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
import StatusBadge from "@/components/status-badge"
import { Button } from "@/components/ui/button"
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

  return (
    <AdaptableDialog
      desktopVariant="sheet-bottom"
      open={open}
      onOpenChange={(isOpen) => !isOpen && onClose()}
    >
      <AdaptableDialogContent side="bottom" showCloseButton={false}>
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
