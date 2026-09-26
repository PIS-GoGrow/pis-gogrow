import { CircleX, Eye, TriangleAlert } from "lucide-react"
import { useTranslation } from "react-i18next"

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
  const payment =
    [...account.payments]
      .sort(
        (first, second) =>
          new Date(second.created_at).getTime() -
          new Date(first.created_at).getTime(),
      )
      .find(({ status }) => status !== "approved") ??
    account.payments.find(({ status }) => status === "approved")

  // Sin comprobante todavía = pendiente; el mismo estado "submitted" cubre
  // tanto el primer envío como un reenvío luego de un rechazo.
  const statusLabel =
    payment?.status === "rejected"
      ? t("pages.accounts.show.status_rejected")
      : payment?.status === "submitted"
        ? t("pages.accounts.show.status_submitted")
        : t("pages.accounts.show.status_pending")

  const statusBadgeClassName =
    payment?.status === "rejected"
      ? "bg-red-100 text-red-700 dark:bg-red-950 dark:text-red-400"
      : payment?.status === "submitted"
        ? "bg-blue-100 text-blue-700 dark:bg-blue-950 dark:text-blue-400"
        : "bg-zinc-200 text-zinc-700 dark:bg-zinc-800 dark:text-zinc-300"

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
    <Card className="bg-zinc-50 dark:bg-zinc-900">
      <CardHeader className="grid gap-4">
        <CardDescription className="flex items-center gap-2">
          {account.month}

          <Badge className={statusBadgeClassName}>{statusLabel}</Badge>

          <Badge
            variant="ghost"
            className={
              account.due_date_passed
                ? "ml-auto text-red-600 dark:text-red-400"
                : "ml-auto text-amber-600 dark:text-amber-400"
            }
          >
            <TriangleAlert />
            {t("pages.accounts.show.due") + account.due_date}
          </Badge>
        </CardDescription>

        <Separator />

        <CardTitle className="flex items-center">
          <span>
            ${account.amount}
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
              className="ml-auto"
              variant="ghost"
            >
              {" "}
              <Eye /> {t("pages.accounts.show.see_detail") + " "}
            </Button>
          </SheetTrigger>
        </CardTitle>

        <Separator />

        {payment?.status === "rejected" && (
          <div className="flex items-start gap-2 rounded-md bg-red-50 p-3 text-sm text-red-700 dark:bg-red-950 dark:text-red-400">
            <CircleX className="mt-0.5 size-4 shrink-0" />
            <p>
              <span className="font-medium">
                {t("pages.accounts.show.status_rejected")}:
              </span>{" "}
              {payment.rejection_reason}
            </p>
          </div>
        )}

        <PaymentReceiptDialog accountId={account.id} payment={payment} />
      </CardHeader>
    </Card>
  )
}
