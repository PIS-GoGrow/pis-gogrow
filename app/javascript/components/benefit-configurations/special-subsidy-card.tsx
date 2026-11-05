import { PencilIcon, Trash2Icon } from "lucide-react"
import { useTranslation } from "react-i18next"

import ListItemCard from "@/components/list-item-card"
import { Button } from "@/components/ui/button"
import {
  CardAction,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import type { SpecialSubsidy } from "@/types/serializers"

interface SpecialSubsidyCardProps {
  subsidy: SpecialSubsidy
  onEdit: () => void
  onDelete: () => void
}

export default function SpecialSubsidyCard({
  subsidy,
  onEdit,
  onDelete,
}: SpecialSubsidyCardProps) {
  const { t } = useTranslation()

  const rows = [
    {
      label: t("pages.admin.benefit_configurations.index.special.discount"),
      value: `${subsidy.subsidy_percentage}%`,
    },
    {
      label: t("pages.admin.benefit_configurations.index.special.applies_to"),
      value: subsidy.applies_to_all
        ? t("pages.admin.benefit_configurations.index.special.applies_to_all")
        : t(
            "pages.admin.benefit_configurations.index.special.applies_to_selection",
          ),
    },
    {
      label: t("pages.admin.benefit_configurations.index.special.condition"),
      value: subsidy.condition
        ? t(
            `pages.admin.benefit_configurations.index.special.conditions.${subsidy.condition.type}`,
          )
        : "—",
    },
  ]

  return (
    <ListItemCard className="gap-3">
      <CardHeader className="gap-x-2 gap-y-0">
        <CardTitle className="row-span-2 self-center leading-6 font-medium">
          {subsidy.name}
        </CardTitle>
        <CardAction className="flex gap-1 self-center">
          <Button
            variant="ghost"
            size="icon-sm"
            aria-label={t(
              "pages.admin.benefit_configurations.index.special.edit",
              { name: subsidy.name },
            )}
            onClick={onEdit}
          >
            <PencilIcon aria-hidden="true" />
          </Button>
          <Button
            variant="ghost"
            size="icon-sm"
            aria-label={t(
              "pages.admin.benefit_configurations.index.special.delete",
              { name: subsidy.name },
            )}
            onClick={onDelete}
          >
            <Trash2Icon aria-hidden="true" />
          </Button>
        </CardAction>
      </CardHeader>
      <CardContent>
        <dl className="flex flex-col gap-2 border-t pt-3">
          {rows.map((row) => (
            <div key={row.label} className="flex items-center justify-between">
              <dt className="text-muted-foreground text-[13px]">{row.label}</dt>
              <dd className="font-semibold">{row.value}</dd>
            </div>
          ))}
        </dl>
      </CardContent>
    </ListItemCard>
  )
}
