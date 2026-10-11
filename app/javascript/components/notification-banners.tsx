import { router, usePage } from "@inertiajs/react"
import { X } from "lucide-react"
import { useState } from "react"

import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { cn } from "@/lib/utils"
import { notifications as notificationRoutes } from "@/routes"
import type { Notification } from "@/types"

function NonDismissableAlertIcon({ className }: { className?: string }) {
  return (
    <svg
      width="15"
      height="14"
      viewBox="0 0 15 14"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      aria-hidden="true"
      className={className}
    >
      <path
        d="M8.69988 12.75H6.13345C3.04651 12.75 1.50304 12.75 0.934243 11.746C0.36545 10.7419 1.15491 9.41095 2.73383 6.74898L4.01705 4.58555C5.53373 2.02852 6.29207 0.75 7.41667 0.75C8.54126 0.75 9.2996 2.02852 10.8163 4.58555L12.0995 6.74898C13.6784 9.41094 14.4679 10.7419 13.8991 11.746C13.3303 12.75 11.7868 12.75 8.69988 12.75Z"
        stroke="#EF4444"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M7.4165 4.75V7.75"
        stroke="#EF4444"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M7.4165 10.0781V10.0848"
        stroke="#EF4444"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}

function DismissableAlertIcon({ className }: { className?: string }) {
  return (
    <svg
      width="15"
      height="15"
      viewBox="0 0 15 15"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      aria-hidden="true"
      className={className}
    >
      <circle
        cx="7.41667"
        cy="7.41667"
        r="6.66667"
        stroke="#0A0A0A"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M7.4165 4.75V7.75"
        stroke="#0A0A0A"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M7.4165 10.0757V10.0824"
        stroke="#0A0A0A"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}

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
            className={
              requiresAction
                ? "rounded-[10px] border-[#E5E5E5] bg-white px-4 py-3 text-[#B91C1C]"
                : "text-foreground"
            }
          >
            {requiresAction ? (
              <NonDismissableAlertIcon className="size-4" />
            ) : (
              <DismissableAlertIcon className="size-4" />
            )}

            <AlertTitle
              className={
                requiresAction
                  ? "text-sm leading-5 font-semibold text-[#B91C1C]"
                  : "text-sm leading-5 font-semibold"
              }
            >
              {notification.title}
            </AlertTitle>

            <AlertDescription
              className={
                requiresAction
                  ? "text-sm leading-5 font-normal text-[#B91C1C]"
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
