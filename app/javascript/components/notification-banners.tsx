import { router, usePage } from "@inertiajs/react"
import { CircleAlert, Info, X } from "lucide-react"
import { useState } from "react"

import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { cn } from "@/lib/utils"
import { notifications as notificationRoutes } from "@/routes"
import type { Notification } from "@/types"

interface NotificationBannersProps {
  className?: string
}

export default function NotificationBanners({
  className,
}: NotificationBannersProps) {
  const notifications = usePage().props.notifications ?? []
  const [closingId, setClosingId] = useState<number | null>(null)

  function closeNotification(notification: Notification) {
    if (notification.requires_action || closingId !== null) return

    setClosingId(notification.id)

    router.patch(
      notificationRoutes.close(notification.id),
      {},
      {
        preserveScroll: true,
        onFinish: () => setClosingId(null),
      },
    )
  }

  if (notifications.length === 0) return null

  return (
    <div className={cn("flex flex-col gap-3", className)}>
      {notifications.map((notification) => {
        const requiresAction = notification.requires_action

        return (
          <Alert
            key={notification.id}
            variant={requiresAction ? "destructive" : "default"}
            className={requiresAction ? undefined : "text-foreground"}
          >
            {requiresAction ? (
              <CircleAlert aria-hidden="true" />
            ) : (
              <Info aria-hidden="true" />
            )}

            <AlertTitle className="text-sm leading-5 font-semibold">
              {notification.title}
            </AlertTitle>

            <AlertDescription
              className={
                requiresAction
                  ? "text-sm leading-5"
                  : "text-foreground text-sm leading-5"
              }
            >
              {notification.description}
            </AlertDescription>

            {!requiresAction && (
              <button
                type="button"
                aria-label="Cerrar notificación"
                disabled={closingId === notification.id}
                onClick={() => closeNotification(notification)}
                className="absolute top-3 right-4 grid size-5 cursor-pointer place-items-center rounded-sm disabled:cursor-default disabled:opacity-50"
              >
                <X className="size-4" aria-hidden="true" />
              </button>
            )}
          </Alert>
        )
      })}
    </div>
  )
}
