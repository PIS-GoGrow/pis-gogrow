import { PercentIcon, PlusIcon } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import {
  AdaptableDialog,
  AdaptableDialogContent,
  AdaptableDialogDescription,
  AdaptableDialogTitle,
} from "@/components/adaptable-dialog"
import DeleteSpecialSubsidyDialog from "@/components/benefit-configurations/delete-special-subsidy-dialog"
import SpecialSubsidyCard from "@/components/benefit-configurations/special-subsidy-card"
import SpecialSubsidyForm from "@/components/benefit-configurations/special-subsidy-form"
import { Button } from "@/components/ui/button"
import {
  Card,
  CardAction,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import {
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyMedia,
  EmptyTitle,
} from "@/components/ui/empty"
import type { Employee, SpecialSubsidy } from "@/types/serializers"

interface SpecialSubsidiesSectionProps {
  specialSubsidies: SpecialSubsidy[]
  employees: Employee[]
}

export default function SpecialSubsidiesSection({
  specialSubsidies,
  employees,
}: SpecialSubsidiesSectionProps) {
  const { t } = useTranslation()
  const [sheetOpen, setAdaptableDialogOpen] = useState(false)
  const [editing, setEditing] = useState<SpecialSubsidy | undefined>()
  const [formKey, setFormKey] = useState(0)
  const [deleting, setDeleting] = useState<SpecialSubsidy | null>(null)

  function openAdaptableDialog(subsidy?: SpecialSubsidy) {
    setEditing(subsidy)
    setFormKey((key) => key + 1)
    setAdaptableDialogOpen(true)
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>
          {t("pages.admin.benefit_configurations.index.special.title")}
        </CardTitle>
        <CardDescription>
          {t("pages.admin.benefit_configurations.index.special.description")}
        </CardDescription>
        <CardAction>
          <Button
            variant="outline"
            size="sm"
            onClick={() => openAdaptableDialog()}
          >
            <PlusIcon aria-hidden="true" />
            {t("pages.admin.benefit_configurations.index.special.add")}
          </Button>
        </CardAction>
      </CardHeader>

      <CardContent>
        {specialSubsidies.length === 0 ? (
          <Empty className="border">
            <EmptyHeader>
              <EmptyMedia variant="icon">
                <PercentIcon aria-hidden="true" />
              </EmptyMedia>
              <EmptyTitle>
                {t(
                  "pages.admin.benefit_configurations.index.special.empty.title",
                )}
              </EmptyTitle>
              <EmptyDescription>
                {t(
                  "pages.admin.benefit_configurations.index.special.empty.description",
                )}
              </EmptyDescription>
            </EmptyHeader>
          </Empty>
        ) : (
          <div className="grid gap-4 md:grid-cols-2">
            {specialSubsidies.map((subsidy) => (
              <SpecialSubsidyCard
                key={subsidy.id}
                subsidy={subsidy}
                onEdit={() => openAdaptableDialog(subsidy)}
                onDelete={() => setDeleting(subsidy)}
              />
            ))}
          </div>
        )}
      </CardContent>

      <AdaptableDialog open={sheetOpen} onOpenChange={setAdaptableDialogOpen}>
        <AdaptableDialogContent
          showCloseButton={false}
          className="p-5"
        >
          <div className="flex flex-col gap-1">
            <AdaptableDialogTitle className="text-base leading-6 font-semibold tracking-normal">
              {editing
                ? t(
                    "pages.admin.benefit_configurations.index.special.form.edit_title",
                  )
                : t(
                    "pages.admin.benefit_configurations.index.special.form.add_title",
                  )}
            </AdaptableDialogTitle>
            <AdaptableDialogDescription>
              {t(
                "pages.admin.benefit_configurations.index.special.form.description",
              )}
            </AdaptableDialogDescription>
          </div>

          <SpecialSubsidyForm
            key={formKey}
            subsidy={editing}
            employees={employees}
            onCancel={() => setAdaptableDialogOpen(false)}
            onSuccess={() => setAdaptableDialogOpen(false)}
          />
        </AdaptableDialogContent>
      </AdaptableDialog>

      <DeleteSpecialSubsidyDialog
        subsidy={deleting}
        onOpenChange={(open) => {
          if (!open) setDeleting(null)
        }}
      />
    </Card>
  )
}
