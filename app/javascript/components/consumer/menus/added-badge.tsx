import { useTranslation } from "react-i18next"

import { Badge } from "@/components/ui/badge"

export default function AddedBadge() {
  const { t } = useTranslation()

  return (
    <Badge
      variant="outline"
      className="gap-1.5 border-none bg-blue-50 px-2 py-0.5 text-blue-700 dark:bg-blue-950 dark:text-blue-300"
    >
      <span className="size-1.5 rounded-full bg-blue-500" />
      {t("pages.consumer_dashboard.index.added")}
    </Badge>
  )
}
