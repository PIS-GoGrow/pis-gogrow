import { CircleAlert, X } from "lucide-react"
import { useTranslation } from "react-i18next"

import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import type { ConsumerClosure } from "@/types"

interface ClosureBannerProps {
  closure: ConsumerClosure
  when: "now" | "soon"
  onDismiss?: () => void
}

const page = "pages.consumer_dashboard.index.closure"

export default function ClosureBanner({
  closure,
  when,
  onDismiss,
}: ClosureBannerProps) {
  const { t } = useTranslation()

  return (
    <Alert className="text-foreground">
      <CircleAlert aria-hidden="true" />
      <AlertTitle className="pr-6 text-sm leading-5 font-semibold">
        {t(`${page}.title_${when}`, { provider: closure.provider_name })}
      </AlertTitle>
      <AlertDescription className="text-foreground text-sm leading-5">
        {t(`${page}.description`, {
          period: closure.period,
          reason: closure.reason,
        })}
      </AlertDescription>

      {onDismiss && (
        <button
          type="button"
          aria-label={t(`${page}.dismiss`)}
          onClick={onDismiss}
          className="absolute top-3 right-4 grid size-5 cursor-pointer place-items-center rounded-sm"
        >
          <X className="size-4" aria-hidden="true" />
        </button>
      )}
    </Alert>
  )
}
