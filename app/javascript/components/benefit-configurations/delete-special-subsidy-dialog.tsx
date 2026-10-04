import { router } from "@inertiajs/react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
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
    <Dialog open={subsidy !== null} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>
            {t(
              "pages.admin.benefit_configurations.index.special.delete_dialog.title",
              { name: subsidy?.name },
            )}
          </DialogTitle>
          <DialogDescription>
            {t(
              "pages.admin.benefit_configurations.index.special.delete_dialog.description",
            )}
          </DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <DialogClose asChild>
            <Button variant="outline">
              {t(
                "pages.admin.benefit_configurations.index.special.delete_dialog.cancel",
              )}
            </Button>
          </DialogClose>
          <Button
            variant="destructive"
            disabled={processing}
            onClick={handleDelete}
          >
            {processing && <Spinner />}
            {t(
              "pages.admin.benefit_configurations.index.special.delete_dialog.confirm",
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
