import { Link, router } from "@inertiajs/react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import RemoveScheduleDialog from "@/components/schedules/remove-schedule-dialog"
import {
  Card,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { Switch } from "@/components/ui/switch"
import { useFormatters } from "@/hooks/use-formatters"
import { cn } from "@/lib/utils"
import { providerMenus, schedules as schedulesRoutes } from "@/routes"
import type { Schedule } from "@/types"

interface PublishedDayViewProps {
  schedules: Schedule[]
  publishable: boolean
  returnTo: string
}

function PublishedScheduleRow({
  schedule,
  publishable,
  returnTo,
}: {
  schedule: Schedule
  publishable: boolean
  returnTo: string
}) {
  const { t } = useTranslation()
  const { formatMoneyShort } = useFormatters()
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
    <Card
      className={cn(
        "relative w-full",
        publishable && "hover:bg-muted/40 transition-colors",
      )}
    >
      <CardHeader>
        <CardTitle>
          {publishable ? (
            <Link
              href={
                providerMenus.edit(schedule.saved_menu_id, {
                  query: { schedule_id: schedule.id, return_to: returnTo },
                }).url
              }
              aria-label={t("pages.schedules.index.edit_dish", {
                name: schedule.menu.name,
              })}
              className="after:absolute after:inset-0 after:rounded-xl"
            >
              {schedule.menu.name}{" "}
              <span className="text-muted-foreground">
                | {formatMoneyShort(schedule.menu.price ?? 0)}
              </span>
            </Link>
          ) : (
            <>
              {schedule.menu.name}{" "}
              <span className="text-muted-foreground">
                | {formatMoneyShort(schedule.menu.price ?? 0)}
              </span>
            </>
          )}
        </CardTitle>
        <CardDescription>{schedule.menu.description}</CardDescription>
      </CardHeader>

      {publishable && (
        <CardFooter className="justify-between border-t">
          <RemoveScheduleDialog schedule={schedule} />
          <label className="relative z-10 flex items-center gap-2 text-sm">
            {t("pages.schedules.index.availability.toggle_label")}
            <Switch
              checked={schedule.available}
              disabled={processing}
              onCheckedChange={handleAvailabilityChange}
              className="data-[state=checked]:bg-green-600 dark:data-[state=checked]:bg-green-600"
            />
          </label>
        </CardFooter>
      )}
    </Card>
  )
}

export default function PublishedDayView({
  schedules,
  publishable,
  returnTo,
}: PublishedDayViewProps) {
  return (
    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
      {schedules.map((schedule) => (
        <PublishedScheduleRow
          key={schedule.id}
          schedule={schedule}
          publishable={publishable}
          returnTo={returnTo}
        />
      ))}
    </div>
  )
}
