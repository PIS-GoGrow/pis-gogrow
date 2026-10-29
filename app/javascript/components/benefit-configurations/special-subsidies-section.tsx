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
    <section className="flex flex-col gap-3">
      <div className="flex flex-col gap-1">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-bold text-foreground">
            {t("pages.admin.benefit_configurations.index.special.title")}
          </h2>
          <Button
            variant="ghost"
            size="sm"
            className="gap-1.5 font-semibold text-foreground"
            onClick={() => openAdaptableDialog()}
          >
            <PlusIcon className="size-4" aria-hidden="true" />
            {t("pages.admin.benefit_configurations.index.special.add")}
          </Button>
        </div>
        <p className="text-base text-muted-foreground">
          {t("pages.admin.benefit_configurations.index.special.description")}
        </p>
      </div>

      {specialSubsidies.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-7 px-10 gap-4 text-center">
          <div className="flex items-center justify-center size-10 rounded-[10px] bg-[#F5F5F5] dark:bg-neutral-800 text-foreground">
            <PercentIcon className="size-5" aria-hidden="true" />
          </div>
          <div className="flex flex-col items-center gap-2">
            <h3 className="text-lg font-medium text-foreground">
              {t("pages.admin.benefit_configurations.index.special.empty.title")}
            </h3>
            <p className="text-sm text-muted-foreground max-w-[280px]">
              {t(
                "pages.admin.benefit_configurations.index.special.empty.description",
              )}
            </p>
          </div>
        </div>
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

      <AdaptableDialog open={sheetOpen} onOpenChange={setAdaptableDialogOpen}>
        <AdaptableDialogContent showCloseButton={false} className="p-5">
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
    </section>
  )
}
