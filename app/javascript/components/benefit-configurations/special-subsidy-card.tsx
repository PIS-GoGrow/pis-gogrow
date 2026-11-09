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
    <ListItemCard>
      <CardHeader>
        <CardTitle>{subsidy.name}</CardTitle>
        <CardAction className="flex gap-1">
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
        <dl className="divide-border bg-muted divide-y rounded-lg px-4">
          {rows.map((row) => (
            <div
              key={row.label}
              className="flex items-center justify-between py-2"
            >
              <dt className="text-muted-foreground text-sm">{row.label}</dt>
              <dd className="font-semibold">{row.value}</dd>
            </div>
          ))}
        </dl>
      </CardContent>
    </ListItemCard>
  )
}
