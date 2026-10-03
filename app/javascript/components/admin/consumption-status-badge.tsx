import { useTranslation } from "react-i18next"

import StatusBadge from "@/components/status-badge"
import { Badge } from "@/components/ui/badge"
import type { PaymentStatus } from "@/types"

interface ConsumptionStatusBadgeProps {
  // null es un mes sin nada que cobrar, que no es un estado de Payment.
  status: PaymentStatus | null
}

export default function ConsumptionStatusBadge({
  status,
}: ConsumptionStatusBadgeProps) {
  const { t } = useTranslation()

  if (status) return <StatusBadge status={status} kind="payment" />

  return (
    <Badge
      variant="outline"
      className="text-muted-foreground [&>span]:bg-muted-foreground gap-1.5 px-2.5 py-1"
    >
      <span className="size-1.5 rounded-full" />
      {t("pages.admin.consumers.index.no_consumption")}
    </Badge>
  )
}
