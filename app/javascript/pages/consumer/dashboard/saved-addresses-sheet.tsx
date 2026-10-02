import { MapPin } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import { Button } from "@/components/ui/button"
import { RadioGroup } from "@/components/ui/radio-group"
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet"

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
    <Sheet
      open={open}
      onOpenChange={(nextOpen) => {
        setOpen(nextOpen)
        if (nextOpen) setDraft(address)
      }}
    >
      <SheetTrigger asChild>
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
      </SheetTrigger>

      <SheetContent
        side="bottom"
        showCloseButton={false}
        className="border-border bg-background text-foreground max-h-[85svh] gap-6 overflow-y-auto rounded-t-[32px] border px-6 pt-2.5 pb-8 shadow-none md:inset-x-1/2 md:bottom-1/2 md:w-[402px] md:translate-x-[-50%] md:translate-y-1/2 md:rounded-[32px]"
      >
        <div
          aria-hidden="true"
          className="bg-muted-foreground/30 mx-auto h-1 w-12 rounded-full"
        />

        <div className="flex flex-col gap-5">
          <SheetTitle className="text-base leading-6 font-semibold tracking-normal">
            {t("pages.cart.saved_addresses.title")}
          </SheetTitle>
          <SheetDescription className="sr-only">
            {t("pages.cart.saved_addresses.description")}
          </SheetDescription>

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
      </SheetContent>
    </Sheet>
  )
}
