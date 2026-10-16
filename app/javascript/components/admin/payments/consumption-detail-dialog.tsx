import { SlidersHorizontal } from "lucide-react"
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
import ConsumptionDayList from "@/components/collections/consumption-day-list"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Button } from "@/components/ui/button"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuRadioGroup,
  DropdownMenuRadioItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { Separator } from "@/components/ui/separator"
import { Spinner } from "@/components/ui/spinner"
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
import { useInitials } from "@/hooks/use-initials"
import type { AdminPaymentsIndex } from "@/types"

export type ConsumptionDetail = NonNullable<AdminPaymentsIndex["period"]>
type DetailOrder =
  ConsumptionDetail["providers"][number]["days"][number]["orders"][number]

interface ConsumptionDetailDialogProps {
  detail: ConsumptionDetail | null
  providerId: number | null
  onProviderChange: (providerId: number) => void
  loading: boolean
  open: boolean
  onOpenChange: (open: boolean) => void
}

const page = "pages.admin.payments.index.detail"

export default function ConsumptionDetailDialog({
  detail,
  providerId,
  onProviderChange,
  loading,
  open,
  onOpenChange,
}: ConsumptionDetailDialogProps) {
  const { t } = useTranslation()
  const { formatMoneyShort } = useFormatters()
  const getInitials = useInitials()

  const providers = detail?.providers ?? []
  const provider =
    providers.find((option) => option.id === providerId) ?? providers[0]

  return (
    <AdaptableDialog open={open} onOpenChange={onOpenChange}>
      <AdaptableDialogContent
        showCloseButton={false}
        className="gap-4 p-4 sm:max-w-xl"
      >
        <AdaptableDialogHeader className="p-0 text-left">
          <AdaptableDialogTitle>
            {provider && detail
              ? t(`${page}.title`, {
                  provider: provider.name,
                  month: detail.month,
                })
              : t(`${page}.loading_title`)}
          </AdaptableDialogTitle>
          <AdaptableDialogDescription className="sr-only">
            {t(`${page}.description`)}
          </AdaptableDialogDescription>
        </AdaptableDialogHeader>

        {loading || !provider ? (
          <Spinner className="mx-auto size-8" />
        ) : (
          <>
            {providers.length > 1 && (
              <div className="flex items-center justify-between gap-2">
                <p className="text-sm">
                  {t(`${page}.provider`)}{" "}
                  <span className="text-muted-foreground">{provider.name}</span>
                </p>
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <Button
                      variant="outline"
                      size="icon"
                      className="rounded-full"
                      aria-label={t(`${page}.filter_providers`)}
                    >
                      <SlidersHorizontal aria-hidden="true" />
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end">
                    <DropdownMenuRadioGroup
                      value={String(provider.id)}
                      onValueChange={(value) => onProviderChange(Number(value))}
                    >
                      {providers.map((option) => (
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
            )}

            <Tabs defaultValue="payment" className="min-h-0 gap-4">
              <TabsList className="w-full">
                <TabsTrigger value="payment">
                  {t(`${page}.payment_tab`)}
                </TabsTrigger>
                <TabsTrigger value="meals">
                  {t(`${page}.meals_tab`)}
                </TabsTrigger>
              </TabsList>

              <TabsContent value="payment">
                <dl className="grid gap-4 rounded-xl border p-4">
                  <div className="grid gap-1">
                    <dt className="text-muted-foreground text-sm">
                      {t(`${page}.subtotal`)}
                    </dt>
                    <dd>
                      {formatMoneyShort(provider.subtotal)}{" "}
                      <span className="text-muted-foreground">
                        |{" "}
                        {t("pages.admin.payments.index.meals", {
                          count: provider.meals,
                        })}
                      </span>
                    </dd>
                  </div>
                  <Separator />
                  <div className="grid gap-1">
                    <dt className="text-muted-foreground text-sm">
                      {t(`${page}.vat`, { rate: provider.vat_rate })}
                    </dt>
                    <dd>{formatMoneyShort(provider.vat_amount)}</dd>
                  </div>
                  <Separator />
                  <div className="grid gap-1">
                    <dt className="text-muted-foreground text-sm">
                      {t(`${page}.total`)}
                    </dt>
                    <dd>{formatMoneyShort(provider.payable_amount)}</dd>
                  </div>
                </dl>
              </TabsContent>

              <TabsContent
                value="meals"
                className="max-h-[50dvh] overflow-y-auto"
              >
                <ConsumptionDayList
                  days={provider.days}
                  mealsOf={(order: DetailOrder) => order.meals}
                  amountOf={(order: DetailOrder) => order.company_amount}
                  formatAmount={formatMoneyShort}
                  emptyLabel={t(`${page}.empty`)}
                >
                  {(orders) => (
                    <Table>
                      <TableHeader className="bg-muted/70">
                        <TableRow>
                          <TableHead>{t(`${page}.user`)}</TableHead>
                          <TableHead className="text-center">
                            {t(`${page}.quantity`)}
                          </TableHead>
                          <TableHead className="text-right">
                            {t(`${page}.employee`)}
                          </TableHead>
                          <TableHead className="text-right">
                            {t(`${page}.company`)}
                          </TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {orders.map((order) => (
                          <TableRow key={order.id}>
                            <TableCell>
                              <Avatar title={order.consumer_name}>
                                {order.avatar_url && (
                                  <AvatarImage src={order.avatar_url} alt="" />
                                )}
                                <AvatarFallback className="text-xs font-semibold">
                                  {getInitials(order.consumer_name)}
                                </AvatarFallback>
                              </Avatar>
                              <span className="sr-only">
                                {order.consumer_name}
                              </span>
                            </TableCell>
                            <TableCell className="text-center">
                              {order.meals}
                            </TableCell>
                            <TableCell className="text-right">
                              {formatMoneyShort(order.employee_amount)}
                            </TableCell>
                            <TableCell className="text-right">
                              {formatMoneyShort(order.company_amount)}
                            </TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  )}
                </ConsumptionDayList>
              </TabsContent>
            </Tabs>
          </>
        )}

        <AdaptableDialogFooter className="p-0 sm:flex-col">
          <AdaptableDialogClose asChild>
            <Button className="w-full">{t("common.close")}</Button>
          </AdaptableDialogClose>
        </AdaptableDialogFooter>
      </AdaptableDialogContent>
    </AdaptableDialog>
  )
}
