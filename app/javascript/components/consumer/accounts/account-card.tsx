import { Eye, TriangleAlert } from "lucide-react"
import { useTranslation } from "react-i18next"

import RejectionNotice from "@/components/payments/rejection-notice"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import {
  Card,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { Separator } from "@/components/ui/separator"
import { SheetTrigger } from "@/components/ui/sheet"
import { formatMoney } from "@/lib/money"
import { pendingRejectionReason } from "@/lib/payment-rejection-reasons"
import { consumerAccounts } from "@/routes"
import type { Account, SimplifiedOrder } from "@/types"

import PaymentReceiptDialog from "./payment-receipt-dialog"

interface AccountDetail {
  orders: SimplifiedOrder[]
  month: string
  amount: number
}

interface AccountCardProps {
  account: Account
  setDetail: React.Dispatch<React.SetStateAction<AccountDetail | null>>
  setLoading: React.Dispatch<React.SetStateAction<boolean>>
}

export default function AccountCard({
  account,
  setDetail,
  setLoading,
}: AccountCardProps) {
  const { t } = useTranslation()
  const payments = [...account.payments].sort(
    (first, second) =>
      new Date(second.created_at).getTime() -
      new Date(first.created_at).getTime(),
  )
  const rejectionReason = pendingRejectionReason(payments)
  const showReceiptSection =
    !account.current || account.payments.some(({ receipt_url }) => receipt_url)

  async function handleClick() {
    setLoading(true)
    try {
      const response = await fetch(consumerAccounts.show(account.id).url, {
        headers: { Accept: "application/json" },
      })

      if (!response.ok) {
        throw new Error(`Error ${response.status}`)
      }

      const data = (await response.json()) as AccountDetail
      setDetail(data)
    } catch (err) {
      console.error(err)
    } finally {
      setLoading(false)
    }
  }

  return (
    <Card className="bg-muted py-4 shadow-none">
      <CardHeader className="grid grid-cols-1 gap-3 px-4">
        <CardDescription className="flex flex-wrap items-center gap-2">
          <span className="shrink-0 whitespace-nowrap">{account.month}</span>

          <Badge
            variant="ghost"
            className={
              account.due_date_passed
                ? "ml-auto shrink-0 text-red-600 dark:text-red-400"
                : "ml-auto shrink-0 text-amber-600 dark:text-amber-400"
            }
          >
            <TriangleAlert />
            {t("pages.accounts.show.due") + account.due_date}
          </Badge>
        </CardDescription>

        <Separator />

        <CardTitle className="flex flex-wrap items-center gap-2">
          <span className="shrink-0 whitespace-nowrap">
            {formatMoney(account.outstanding_amount)}
            <span className="text-zinc-500 dark:text-zinc-400">
              {" | "}
              {account.orders_amount_sum}{" "}
              {account.orders_amount_sum == 1
                ? t("pages.accounts.show.lunch")
                : t("pages.accounts.show.lunches")}
            </span>
          </span>
          <SheetTrigger asChild>
            <Button
              onClick={() => {
                void handleClick()
              }}
              className="ml-auto h-auto shrink-0 p-0 font-semibold hover:bg-transparent has-[>svg]:px-0 dark:hover:bg-transparent"
              variant="ghost"
            >
              {" "}
              <Eye /> {t("pages.accounts.show.see_detail") + " "}
            </Button>
          </SheetTrigger>
        </CardTitle>

        {(rejectionReason !== null || showReceiptSection) && <Separator />}

        {rejectionReason && (
          <RejectionNotice
            reason={rejectionReason}
            partialPaymentWarning={t(
              "pages.accounts.show.partial_payment_warning",
            )}
            rejectedLabel={t("pages.accounts.show.status_rejected")}
          />
        )}

        {showReceiptSection && (
          <PaymentReceiptDialog
            accountId={account.id}
            inlineUpload
            canUpload={
              !account.current && account.collection_status !== "approved"
            }
            uploadDisabled={account.payments.some(
              ({ status }) => status === "submitted",
            )}
            payments={payments}
          />
        )}
      </CardHeader>
    </Card>
  )
}
