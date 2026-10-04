import { MapPin } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import {
  AdaptableDialog,
  AdaptableDialogContent,
  AdaptableDialogDescription,
  AdaptableDialogTitle,
  AdaptableDialogTrigger,
} from "@/components/adaptable-dialog"
import { Button } from "@/components/ui/button"
import { RadioGroup } from "@/components/ui/radio-group"

import { AddressOption } from "./address-option"
import type { DeliveryAddressOption } from "./consumer-types"

interface Props {
  addresses: DeliveryAddressOption[]
  address: string
  disabled?: boolean
  onSelect: (address: string) => void
}

export function SavedAddressesSheet({
  addresses,
  address,
  disabled = false,
  onSelect,
}: Props) {
  const { t } = useTranslation()
  const [open, setOpen] = useState(false)
  const [draft, setDraft] = useState(address)

  return (
    <AdaptableDialog
      open={open}
      onOpenChange={(nextOpen) => {
        setOpen(nextOpen)
        if (nextOpen) setDraft(address)
      }}
    >
      <AdaptableDialogTrigger asChild>
        <Button
          type="button"
          variant="ghost"
          size="sm"
          disabled={disabled}
          className="text-foreground mt-3 h-auto gap-1.5 px-0 text-xs font-semibold hover:bg-transparent"
        >
          <MapPin aria-hidden="true" className="size-4" />
          {t("pages.cart.my_addresses")}
        </Button>
      </AdaptableDialogTrigger>

      <AdaptableDialogContent showCloseButton={false} className="p-5">
        <div className="flex flex-col gap-5">
          <AdaptableDialogTitle className="text-base leading-6 font-semibold tracking-normal">
            {t("pages.cart.saved_addresses.title")}
          </AdaptableDialogTitle>
          <AdaptableDialogDescription className="sr-only">
            {t("pages.cart.saved_addresses.description")}
          </AdaptableDialogDescription>

          <RadioGroup value={draft} onValueChange={setDraft} className="gap-3">
            {addresses.map((option) => (
              <AddressOption
                key={option.id}
                option={option}
                selected={draft === option.address}
              />
            ))}
          </RadioGroup>

          <div className="grid grid-cols-2 gap-3">
            <Button
              type="button"
              variant="secondary"
              className="bg-secondary text-secondary-foreground hover:bg-secondary/80 hover:text-secondary-foreground h-12 rounded-lg text-base font-medium shadow-none"
              onClick={() => setOpen(false)}
            >
              {t("pages.cart.saved_addresses.cancel")}
            </Button>
            <Button
              type="button"
              disabled={!draft}
              className="bg-primary text-primary-foreground hover:bg-primary/90 h-12 rounded-lg text-base font-medium shadow-none"
              onClick={() => {
                onSelect(draft)
                setOpen(false)
              }}
            >
              {t("pages.cart.saved_addresses.submit")}
            </Button>
          </div>
        </div>
      </AdaptableDialogContent>
    </AdaptableDialog>
  )
}
