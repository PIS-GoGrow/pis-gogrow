import { router } from "@inertiajs/react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import {
  AdaptableDialog,
  AdaptableDialogClose,
  AdaptableDialogContent,
  AdaptableDialogDescription,
  AdaptableDialogFooter,
  AdaptableDialogHeader,
  AdaptableDialogTitle,
} from "@/components/adaptable-dialog"
import { Button } from "@/components/ui/button"
import { Spinner } from "@/components/ui/spinner"
import { adminSpecialSubsidies } from "@/routes"
import type { SpecialSubsidy } from "@/types/serializers"

interface DeleteSpecialSubsidyDialogProps {
  subsidy: SpecialSubsidy | null
  onOpenChange: (open: boolean) => void
}

export default function DeleteSpecialSubsidyDialog({
  subsidy,
  onOpenChange,
}: DeleteSpecialSubsidyDialogProps) {
  const { t } = useTranslation()
  const [processing, setProcessing] = useState(false)

  function handleDelete() {
    if (!subsidy) return

    setProcessing(true)
    router.delete(adminSpecialSubsidies.destroy(subsidy.id).url, {
      preserveScroll: true,
      onSuccess: () => onOpenChange(false),
      onFinish: () => setProcessing(false),
    })
  }

  return (
    <AdaptableDialog open={subsidy !== null} onOpenChange={onOpenChange}>
      <AdaptableDialogContent showCloseButton={false} className="p-5 md:p-6">
        <AdaptableDialogHeader className="p-0">
          <AdaptableDialogTitle>
            {t(
              "pages.admin.benefit_configurations.index.special.delete_dialog.title",
              { name: subsidy?.name },
            )}
          </AdaptableDialogTitle>
          <AdaptableDialogDescription>
            {t(
              "pages.admin.benefit_configurations.index.special.delete_dialog.description",
            )}
          </AdaptableDialogDescription>
        </AdaptableDialogHeader>
        <AdaptableDialogFooter className="p-0 max-md:flex-row max-md:gap-3">
          <AdaptableDialogClose asChild>
            <Button variant="outline" className="max-md:flex-1">
              {t(
                "pages.admin.benefit_configurations.index.special.delete_dialog.cancel",
              )}
            </Button>
          </AdaptableDialogClose>
          <Button
            variant="destructive"
            className="max-md:flex-1"
            disabled={processing}
            onClick={handleDelete}
          >
            {processing && <Spinner />}
            {t(
              "pages.admin.benefit_configurations.index.special.delete_dialog.confirm",
            )}
          </Button>
        </AdaptableDialogFooter>
      </AdaptableDialogContent>
    </AdaptableDialog>
  )
}
