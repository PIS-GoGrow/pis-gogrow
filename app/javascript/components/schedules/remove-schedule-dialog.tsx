import { router } from "@inertiajs/react"
import { X } from "lucide-react"
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
  AdaptableDialogTrigger,
} from "@/components/adaptable-dialog"
import { Button } from "@/components/ui/button"
import { Spinner } from "@/components/ui/spinner"
import { schedules as schedulesRoutes } from "@/routes"
import type { Schedule } from "@/types"

interface RemoveScheduleDialogProps {
  schedule: Schedule
}

export default function RemoveScheduleDialog({
  schedule,
}: RemoveScheduleDialogProps) {
  const { t } = useTranslation()
  const [open, setOpen] = useState(false)
  const [processing, setProcessing] = useState(false)

  function handleRemove() {
    setProcessing(true)

    router.delete(schedulesRoutes.destroy(schedule.id).url, {
      preserveScroll: true,
      preserveState: true,
      onSuccess: () => setOpen(false),
      onFinish: () => setProcessing(false),
    })
  }

  return (
    <AdaptableDialog open={open} onOpenChange={setOpen}>
      <AdaptableDialogTrigger asChild>
        <Button variant="ghost" size="sm" className="relative z-10">
          <X aria-hidden="true" />
          {t("pages.schedules.index.remove.button")}
        </Button>
      </AdaptableDialogTrigger>

      <AdaptableDialogContent showCloseButton={false} className="p-5 md:p-6">
        <AdaptableDialogHeader className="p-0">
          <AdaptableDialogTitle>
            {t("pages.schedules.index.remove.title", {
              name: schedule.menu.name,
            })}
          </AdaptableDialogTitle>
          <AdaptableDialogDescription>
            {t("pages.schedules.index.remove.description")}
          </AdaptableDialogDescription>
        </AdaptableDialogHeader>
        <AdaptableDialogFooter className="p-0 max-md:flex-row max-md:gap-3">
          <AdaptableDialogClose asChild>
            <Button variant="outline" className="max-md:flex-1">
              {t("pages.schedules.index.remove.cancel")}
            </Button>
          </AdaptableDialogClose>
          <Button
            disabled={processing}
            onClick={handleRemove}
            className="max-md:flex-1"
          >
            {processing && <Spinner />}
            {t("pages.schedules.index.remove.confirm")}
          </Button>
        </AdaptableDialogFooter>
      </AdaptableDialogContent>
    </AdaptableDialog>
  )
}
