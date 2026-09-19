import { Eye, TriangleAlert } from "lucide-react"
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
        <CardDescription className="flex">
          {account.month}

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
            ${account.orders_price_sum}
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

        <Button> {t("pages.accounts.show.receipt")} </Button>
      </CardHeader>
    </Card>
  )
}
