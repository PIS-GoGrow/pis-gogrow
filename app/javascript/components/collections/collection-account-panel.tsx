import { Link } from "@inertiajs/react"
import { Eye, TriangleAlert } from "lucide-react"
import { useTranslation } from "react-i18next"

import { buttonVariants } from "@/components/ui/button"
import { useFormatters } from "@/hooks/use-formatters"
import { cn } from "@/lib/utils"
import { providerCollections } from "@/routes"
import type { ProviderCollectionAccount } from "@/types"

interface CollectionAccountPanelProps {
  account: ProviderCollectionAccount
  // Qué encabeza el recuadro: el mes con su vencimiento mientras se espera el
  // cobro, la fecha de pago una vez cobrado, o nada si la fila ya la muestra.
  heading?: "month" | "paid_on" | "none"
}

export default function CollectionAccountPanel({
  account,
  heading = "month",
}: CollectionAccountPanelProps) {
  const { t } = useTranslation()
  const { formatMoney } = useFormatters()

  return (
    <div className="bg-muted/60 grid gap-3 rounded-lg p-3">
      {heading === "paid_on" && (
        <span className="text-muted-foreground text-sm">{account.paid_on}</span>
      )}

      {heading === "month" && (
        <div className="flex flex-wrap items-center justify-between gap-2 text-sm">
          <span className="text-muted-foreground">{account.month}</span>
          {account.status !== "approved" && (
            <span
              className={cn(
                "flex items-center gap-1.5 text-xs",
                account.overdue
                  ? "text-red-600 dark:text-red-400"
                  : "text-muted-foreground",
              )}
            >
              {account.overdue && (
                <TriangleAlert className="size-3.5" aria-hidden="true" />
              )}
              {t("pages.provider_collections.group.due", {
                date: account.due_date,
              })}
            </span>
          )}
        </div>
      )}

      <div className="flex flex-wrap items-center justify-between gap-2">
        <p>
          <strong className="text-lg">{formatMoney(account.amount)}</strong>
          <span className="text-muted-foreground">
            {" | "}
            {t("pages.provider_collections.meals", { count: account.meals })}
          </span>
        </p>
        <Link
          href={providerCollections.show(account.id)}
          className={cn(
            buttonVariants({ variant: "ghost", size: "sm" }),
            "-mr-2.5",
          )}
        >
          <Eye aria-hidden="true" />
          {t("pages.provider_collections.group.detail")}
        </Link>
      </div>
    </div>
  )
}
