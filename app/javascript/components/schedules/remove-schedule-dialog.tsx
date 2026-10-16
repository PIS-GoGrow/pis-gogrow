import { router } from "@inertiajs/react"
import { X } from "lucide-react"
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
  DialogTrigger,
} from "@/components/ui/dialog"
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
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button variant="ghost" size="sm" className="relative z-10">
          <X aria-hidden="true" />
          {t("pages.schedules.index.remove.button")}
        </Button>
      </DialogTrigger>

      <DialogContent>
        <DialogHeader>
          <DialogTitle>
            {t("pages.schedules.index.remove.title", {
              name: schedule.menu.name,
            })}
          </DialogTitle>
          <DialogDescription>
            {t("pages.schedules.index.remove.description")}
          </DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <DialogClose asChild>
            <Button variant="outline">
              {t("pages.schedules.index.remove.cancel")}
            </Button>
          </DialogClose>
          <Button disabled={processing} onClick={handleRemove}>
            {processing && <Spinner />}
            {t("pages.schedules.index.remove.confirm")}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
