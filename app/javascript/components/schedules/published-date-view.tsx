import { router } from "@inertiajs/react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { Switch } from "@/components/ui/switch"
import { schedules as schedulesRoutes } from "@/routes"
import type { Schedule } from "@/types"

interface PublishedDayViewProps {
  schedules: Schedule[]
}

function PublishedScheduleRow({ schedule }: { schedule: Schedule }) {
  const { t } = useTranslation()
  const [processing, setProcessing] = useState(false)

  function handleAvailabilityChange(available: boolean) {
    setProcessing(true)

    router.patch(
      schedulesRoutes.availability(schedule.id).url,
      { available },
      {
        preserveScroll: true,
        preserveState: true,
        onFinish: () => setProcessing(false),
      },
    )
  }

  return (
    <Card className="w-full">
      <CardHeader>
        <CardTitle>
          {schedule.menu.name} | {schedule.menu.price}$
        </CardTitle>
        <CardDescription>{schedule.menu.description}</CardDescription>
      </CardHeader>

      <CardContent className="flex items-center justify-end">
        <label className="flex items-center gap-2 text-sm">
          {t("pages.schedules.index.availability.toggle_label")}
          <Switch
            checked={schedule.available}
            disabled={processing}
            onCheckedChange={handleAvailabilityChange}
            className="data-[state=checked]:bg-green-600 dark:data-[state=checked]:bg-green-600"
          />
        </label>
      </CardContent>
    </Card>
  )
}

export default function PublishedDayView({ schedules }: PublishedDayViewProps) {
  return (
    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
      {schedules.map((schedule) => (
        <PublishedScheduleRow key={schedule.id} schedule={schedule} />
      ))}
    </div>
  )
}
