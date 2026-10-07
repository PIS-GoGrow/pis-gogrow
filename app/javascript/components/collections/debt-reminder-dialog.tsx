import { useRef, useState } from "react"
import { useTranslation } from "react-i18next"

import {
  AdaptableDialog,
  AdaptableDialogContent,
  AdaptableDialogDescription,
  AdaptableDialogFooter,
  AdaptableDialogHeader,
  AdaptableDialogTitle,
  AdaptableDialogTrigger,
} from "@/components/adaptable-dialog"
import { Button } from "@/components/ui/button"
import { Spinner } from "@/components/ui/spinner"
import { useFormatters } from "@/hooks/use-formatters"

type ReminderState = "confirm" | "processing" | "success" | "error"

interface DebtReminderDialogProps {
  employeeName: string
  month: string
  amount: number
  onSent: () => void
}

function simulateReminder() {
  return new Promise<void>((resolve) => setTimeout(resolve, 1200))
}

export default function DebtReminderDialog({
  employeeName,
  month,
  amount,
  onSent,
}: DebtReminderDialogProps) {
  const { t } = useTranslation()
  const { formatMoney } = useFormatters()
  const [open, setOpen] = useState(false)
  const [state, setState] = useState<ReminderState>("confirm")
  const sending = useRef(false)
  const key = "pages.provider_collections.reminder"
  const period = month.replace(" ", " de ").toLocaleLowerCase("es-UY")

  function handleOpenChange(nextOpen: boolean) {
    if (sending.current) return

    if (!nextOpen) {
      if (state === "success") onSent()
      setState("confirm")
    }

    setOpen(nextOpen)
  }

  async function handleSend() {
    if (sending.current) return

    sending.current = true
    setState("processing")

    try {
      await simulateReminder()
      setState("success")
    } catch {
      setState("error")
    } finally {
      sending.current = false
    }
  }

  return (
    <AdaptableDialog open={open} onOpenChange={handleOpenChange}>
      <AdaptableDialogTrigger asChild>
        <Button className="w-full" size="lg">
          {t(`${key}.trigger`)}
        </Button>
      </AdaptableDialogTrigger>

      <AdaptableDialogContent
        showCloseButton={false}
        className="gap-0 rounded-t-3xl pb-[env(safe-area-inset-bottom)] md:gap-4 md:rounded-lg md:pb-6"
      >
        <div
          className="bg-muted-foreground/30 mx-auto mt-3 h-1 w-10 rounded-full md:hidden"
          aria-hidden="true"
        />

        <AdaptableDialogHeader className="items-start px-6 pt-8 text-left md:px-0 md:pt-0">
          <AdaptableDialogTitle className="text-base">
            {t(
              `${key}.${state === "success" || state === "error" ? state : "confirm"}.title`,
            )}
          </AdaptableDialogTitle>
          <AdaptableDialogDescription className="text-base">
            {state === "success"
              ? t(`${key}.success.description`, { employeeName, month: period })
              : state === "error"
                ? t(`${key}.error.description`)
                : t(`${key}.confirm.description`, {
                    employeeName,
                    month: period,
                    amount: formatMoney(amount),
                  })}
          </AdaptableDialogDescription>
        </AdaptableDialogHeader>

        <AdaptableDialogFooter className="flex-row gap-3 px-6 pt-6 pb-6 md:px-0 md:pt-0 md:pb-0">
          {state === "success" ? (
            <Button
              className="h-11 w-full"
              onClick={() => handleOpenChange(false)}
            >
              {t(`${key}.done`)}
            </Button>
          ) : (
            <>
              <Button
                variant="secondary"
                className="h-11 flex-1"
                disabled={state === "processing"}
                onClick={() => handleOpenChange(false)}
              >
                {t(`${key}.back`)}
              </Button>
              <Button
                className="h-11 flex-1"
                disabled={state === "processing"}
                onClick={() => void handleSend()}
              >
                {state === "processing" && <Spinner />}
                {t(
                  `${key}.${state === "error" ? "retry" : state === "processing" ? "sending" : "send"}`,
                )}
              </Button>
            </>
          )}
        </AdaptableDialogFooter>
      </AdaptableDialogContent>
    </AdaptableDialog>
  )
}
