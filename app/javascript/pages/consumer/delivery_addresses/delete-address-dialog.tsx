import { router } from "@inertiajs/react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import {
  AdaptableDialog,
  AdaptableDialogContent,
  AdaptableDialogDescription,
  AdaptableDialogFooter,
  AdaptableDialogHeader,
  AdaptableDialogTitle,
} from "@/components/adaptable-dialog"
import { Button } from "@/components/ui/button"
import { Spinner } from "@/components/ui/spinner"
import { consumerDeliveryAddresses } from "@/routes"
import type { ConsumerDeliveryAddress } from "@/types"

type DeleteState = "confirm" | "processing" | "success"

interface Props {
  address: ConsumerDeliveryAddress | null
  open: boolean
  onOpenChange: (open: boolean) => void
}

export default function DeleteAddressDialog({
  address,
  open,
  onOpenChange,
}: Props) {
  const { t } = useTranslation()
  const [state, setState] = useState<DeleteState>("confirm")
  const key = "pages.consumer_delivery_addresses.delete"

  function handleOpenChange(nextOpen: boolean) {
    if (state === "processing") return

    if (!nextOpen) {
      setState("confirm")
    }

    onOpenChange(nextOpen)
  }

  function handleDelete() {
    if (!address || state === "processing") return

    setState("processing")

    router.delete(consumerDeliveryAddresses.destroy(address.id).url, {
      preserveScroll: true,
      preserveState: true,
      onSuccess: () => setState("success"),
      onFinish: () => {
        setState((current) => (current === "processing" ? "confirm" : current))
      },
    })
  }

  if (!address) return null

  return (
    <AdaptableDialog open={open} onOpenChange={handleOpenChange}>
      <AdaptableDialogContent
        showCloseButton={false}
        className="gap-0 rounded-t-[26px] px-6 pt-2.5 pb-8 md:max-w-md md:gap-4 md:rounded-lg md:p-6"
      >
        <div
          aria-hidden="true"
          className="mx-auto h-[5px] w-20 rounded-full bg-[#E5E5E5] md:hidden"
        />

        {state === "success" ? (
          <>
            <AdaptableDialogHeader className="items-start pt-6 text-left md:pt-0">
              <AdaptableDialogTitle className="text-base leading-6 font-semibold">
                {t(`${key}.success_title`)}
              </AdaptableDialogTitle>

              <AdaptableDialogDescription className="text-base leading-6">
                {t(`${key}.success_description`)}
              </AdaptableDialogDescription>
            </AdaptableDialogHeader>

            <AdaptableDialogFooter className="pt-5">
              <Button
                type="button"
                className="h-12 w-full rounded-[10px] text-base font-medium"
                onClick={() => handleOpenChange(false)}
              >
                {t(`${key}.done`)}
              </Button>
            </AdaptableDialogFooter>
          </>
        ) : (
          <>
            <AdaptableDialogHeader className="items-start pt-6 text-left md:pt-0">
              <AdaptableDialogTitle className="text-base leading-6 font-semibold">
                {t(`${key}.title`, { name: address.name })}
              </AdaptableDialogTitle>

              <AdaptableDialogDescription className="text-muted-foreground text-base leading-6">
                {t(`${key}.description`)}
              </AdaptableDialogDescription>
            </AdaptableDialogHeader>

            <AdaptableDialogFooter className="grid grid-cols-2 gap-3 pt-5 sm:grid-cols-2">
              <Button
                type="button"
                variant="secondary"
                disabled={state === "processing"}
                className="h-12 rounded-[10px] bg-[#F5F5F5] text-base font-medium text-[#0A0A0A]"
                onClick={() => handleOpenChange(false)}
              >
                {t(`${key}.back`)}
              </Button>

              <Button
                type="button"
                disabled={state === "processing"}
                className="h-12 rounded-[10px] bg-[#171717] text-base font-medium text-[#FAFAFA] hover:bg-[#171717]/90"
                onClick={handleDelete}
              >
                {state === "processing" && <Spinner />}
                {t(
                  state === "processing" ? `${key}.deleting` : `${key}.submit`,
                )}
              </Button>
            </AdaptableDialogFooter>
          </>
        )}
      </AdaptableDialogContent>
    </AdaptableDialog>
  )
}
