import { PercentIcon, PlusIcon } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

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
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetTitle,
} from "@/components/ui/sheet"
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
  const [sheetOpen, setSheetOpen] = useState(false)
  const [editing, setEditing] = useState<SpecialSubsidy | undefined>()
  const [formKey, setFormKey] = useState(0)
  const [deleting, setDeleting] = useState<SpecialSubsidy | null>(null)

  function openSheet(subsidy?: SpecialSubsidy) {
    setEditing(subsidy)
    setFormKey((key) => key + 1)
    setSheetOpen(true)
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
          <Button variant="outline" size="sm" onClick={() => openSheet()}>
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
                onEdit={() => openSheet(subsidy)}
                onDelete={() => setDeleting(subsidy)}
              />
            ))}
          </div>
        )}
      </CardContent>

      <Sheet open={sheetOpen} onOpenChange={setSheetOpen}>
        <SheetContent
          side="bottom"
          showCloseButton={false}
          className="border-border bg-background text-foreground max-h-[90dvh] gap-6 overflow-y-auto rounded-t-[32px] border px-6 pt-2.5 pb-8 shadow-none md:inset-x-1/2 md:bottom-1/2 md:w-[480px] md:translate-x-[-50%] md:translate-y-1/2 md:rounded-[32px]"
        >
          <div
            aria-hidden="true"
            className="bg-muted-foreground/30 mx-auto h-1 w-12 shrink-0 rounded-full"
          />
          <div className="flex flex-col gap-1">
            <SheetTitle className="text-base leading-6 font-semibold tracking-normal">
              {editing
                ? t(
                    "pages.admin.benefit_configurations.index.special.form.edit_title",
                  )
                : t(
                    "pages.admin.benefit_configurations.index.special.form.add_title",
                  )}
            </SheetTitle>
            <SheetDescription>
              {t(
                "pages.admin.benefit_configurations.index.special.form.description",
              )}
            </SheetDescription>
          </div>

          <SpecialSubsidyForm
            key={formKey}
            subsidy={editing}
            employees={employees}
            onCancel={() => setSheetOpen(false)}
            onSuccess={() => setSheetOpen(false)}
          />
        </SheetContent>
      </Sheet>

      <DeleteSpecialSubsidyDialog
        subsidy={deleting}
        onOpenChange={(open) => {
          if (!open) setDeleting(null)
        }}
      />
    </Card>
  )
}
