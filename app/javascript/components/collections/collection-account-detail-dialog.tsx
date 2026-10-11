import { Eye } from "lucide-react"
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
import StatusBadge from "@/components/status-badge"
import TextLink from "@/components/text-link"
import { Button } from "@/components/ui/button"
import { Separator } from "@/components/ui/separator"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { useFormatters } from "@/hooks/use-formatters"
import { providerCollections } from "@/routes"
import type {
  ProviderCollectionAccount,
  ProviderCollectionOrder,
} from "@/types"

interface CollectionAccountDetailDialogProps {
  account: ProviderCollectionAccount
  settled?: boolean
}

const page = "pages.provider_collections.group.detail_dialog"
const VAT_RATE = 0.22

function shortDate(date: string | null) {
  return date?.split("/").slice(0, 2).join("/") ?? "-"
}

function ConsumptionTable({
  account,
  footer = false,
  settled = false,
}: {
  account: ProviderCollectionAccount
  footer?: boolean
  settled?: boolean
}) {
  const { t } = useTranslation()
  const { formatMoney } = useFormatters()

  const amountOf = (order: ProviderCollectionOrder) =>
    account.source === "company" ? order.subsidy : order.charged

  if (account.orders.length === 0) {
    return (
      <p className="text-muted-foreground py-8 text-center text-sm">
        {t(`${page}.empty`)}
      </p>
    )
  }

  return (
    <div className="overflow-hidden rounded-xl border">
      <Table className={settled ? "table-fixed" : "min-w-[33rem] table-fixed"}>
        <TableHeader className="bg-muted/70">
          <TableRow>
            <TableHead className="w-[17%]">{t(`${page}.date`)}</TableHead>
            <TableHead className="w-[43%]">{t(`${page}.dish`)}</TableHead>
            <TableHead className="w-[16%] text-center">
              {t(`${page}.quantity`)}
            </TableHead>
            <TableHead className="w-[24%] text-right">
              {t(`${page}.amount`)}
            </TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {account.orders.map((order) => (
            <TableRow key={order.id}>
              <TableCell>{shortDate(order.delivery_date)}</TableCell>
              <TableCell
                className={
                  settled ? "truncate" : "wrap-anywhere whitespace-normal"
                }
              >
                {order.menu_name}
              </TableCell>
              <TableCell className="text-center">{order.amount}</TableCell>
              <TableCell className="text-right">
                {formatMoney(amountOf(order))}
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>

      {footer && (
        <div className="flex items-center justify-between gap-3 border-t p-3 text-sm">
          <span className="font-medium">
            {t(`${page}.total`, { amount: formatMoney(account.amount) })}
          </span>
          <StatusBadge status={account.status} kind="payment" />
        </div>
      )}
    </div>
  )
}

function CompanyCollection({
  account,
  settled,
}: {
  account: ProviderCollectionAccount
  settled: boolean
}) {
  const { t } = useTranslation()
  const { formatMoney } = useFormatters()
  const vat = account.amount * VAT_RATE
  const total = account.amount + vat

  return (
    <div className="grid gap-4 rounded-lg border p-3">
      <dl className="grid gap-3 text-sm">
        {settled && (
          <>
            <div className="grid gap-1">
              <dt className="text-muted-foreground">{t(`${page}.subtotal`)}</dt>
              <dd className="font-semibold">{formatMoney(account.amount)}</dd>
            </div>
            <Separator />
            <div className="grid gap-1">
              <dt className="text-muted-foreground">{t(`${page}.vat`)}</dt>
              <dd className="font-semibold">{formatMoney(vat)}</dd>
            </div>
            <Separator className="bg-foreground/50" />
          </>
        )}
        <div className="flex items-end justify-between gap-3">
          <div className="grid gap-1">
            <dt className="text-muted-foreground">
              {t(`${page}.total_label`)}
            </dt>
            <dd className="font-semibold">
              {formatMoney(settled ? total : account.amount)}
            </dd>
          </div>
          <StatusBadge status={account.status} kind="payment" />
        </div>
      </dl>
    </div>
  )
}

export default function CollectionAccountDetailDialog({
  account,
  settled = false,
}: CollectionAccountDetailDialogProps) {
  const { t } = useTranslation()

  return (
    <AdaptableDialog>
      <AdaptableDialogTrigger asChild>
        <Button
          variant="ghost"
          size="sm"
          className={settled ? "-mr-2.5" : "-mr-2.5 text-sm font-semibold"}
        >
          <Eye aria-hidden="true" />
          {t("pages.provider_collections.group.detail")}
        </Button>
      </AdaptableDialogTrigger>

      <AdaptableDialogContent
        showCloseButton={false}
        className="gap-0 p-0 sm:max-w-xl"
      >
        <AdaptableDialogHeader className="p-4 pb-3 text-left">
          <AdaptableDialogTitle>
            {t(`${page}.title`, { month: account.month })}
          </AdaptableDialogTitle>
          <AdaptableDialogDescription className="sr-only">
            {t(`${page}.description`, { name: account.owner_name })}
          </AdaptableDialogDescription>
        </AdaptableDialogHeader>

        <div className="max-h-[60dvh] overflow-y-auto px-4">
          {account.source === "company" ? (
            <Tabs defaultValue="collection" className="gap-4">
              <TabsList className="w-full">
                <TabsTrigger value="collection">
                  {t(`${page}.collection_tab`)}
                </TabsTrigger>
                <TabsTrigger value="meals">
                  {t(`${page}.meals_tab`)}
                </TabsTrigger>
              </TabsList>
              <TabsContent value="collection">
                <CompanyCollection account={account} settled={settled} />
              </TabsContent>
              <TabsContent value="meals">
                <ConsumptionTable account={account} settled={settled} />
              </TabsContent>
            </Tabs>
          ) : (
            <ConsumptionTable account={account} footer settled={settled} />
          )}
        </div>

        <AdaptableDialogFooter className={settled ? "p-4" : "p-4 sm:flex-col"}>
          {!settled && account.payments.length > 0 && (
            <TextLink
              href={providerCollections.show(account.id)}
              className="self-center text-sm"
            >
              {t(`${page}.payment_history`)}
            </TextLink>
          )}
          <AdaptableDialogClose asChild>
            <Button className="w-full">{t(`${page}.close`)}</Button>
          </AdaptableDialogClose>
        </AdaptableDialogFooter>
      </AdaptableDialogContent>
    </AdaptableDialog>
  )
}
