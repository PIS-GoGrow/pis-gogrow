import { FilterHorizontalIcon } from "@hugeicons/core-free-icons"
import { HugeiconsIcon } from "@hugeicons/react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import { Button } from "@/components/ui/button"
import { Checkbox } from "@/components/ui/checkbox"
import { Label } from "@/components/ui/label"
import {
  Sheet,
  SheetContent,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet"
import type { DeliveryFilter } from "@/lib/provider-orders"

const options: DeliveryFilter[] = ["all", "office", "home"]

interface DeliveryFilterSheetProps {
  value: DeliveryFilter
  onApply: (value: DeliveryFilter) => void
}

export default function DeliveryFilterSheet({
  value,
  onApply,
}: DeliveryFilterSheetProps) {
  const { t } = useTranslation()
  const [open, setOpen] = useState(false)
  const [draft, setDraft] = useState<DeliveryFilter>(value)

  return (
    <Sheet
      open={open}
      onOpenChange={(nextOpen) => {
        setOpen(nextOpen)
        if (nextOpen) setDraft(value)
      }}
    >
      <SheetTrigger asChild>
        <Button
          type="button"
          variant="outline"
          size="icon"
          aria-label={t("pages.provider_orders.index.delivery_sheet.open")}
          className="border-border bg-card hover:bg-accent size-9 shrink-0 rounded-full shadow-none"
        >
          <HugeiconsIcon
            icon={FilterHorizontalIcon}
            size={20}
            strokeWidth={1.5}
            aria-hidden="true"
          />
        </Button>
      </SheetTrigger>

      <SheetContent
        side="bottom"
        showCloseButton={false}
        data-delivery-filter-sheet
        aria-describedby={undefined}
        className="mx-auto max-h-[90dvh] max-w-md overflow-y-auto rounded-t-xl border-x p-5"
      >
        <div className="flex flex-col gap-5">
          <div
            aria-hidden="true"
            className="bg-muted mx-auto h-1.5 w-14 rounded-full"
          />

          <SheetTitle className="text-base leading-6 font-semibold tracking-normal">
            {t("pages.provider_orders.index.delivery_sheet.title")}
          </SheetTitle>

          <div className="flex flex-col">
            {options.map((option) => (
              <div
                key={option}
                className="flex h-12 items-center gap-3 rounded-sm px-2 py-3"
              >
                <Checkbox
                  id={`delivery-filter-${option}`}
                  checked={draft === option}
                  onCheckedChange={() => setDraft(option)}
                  className="text-foreground data-[state=checked]:text-foreground size-4 rounded-none border-0 bg-transparent shadow-none focus-visible:border-transparent focus-visible:ring-0 data-[state=checked]:border-transparent data-[state=checked]:bg-transparent dark:bg-transparent dark:data-[state=checked]:bg-transparent [&_svg]:size-4"
                />
                <Label
                  htmlFor={`delivery-filter-${option}`}
                  className="flex-1 cursor-pointer text-base leading-6 font-medium tracking-normal"
                >
                  {t(`pages.provider_orders.index.delivery_filters.${option}`)}
                </Label>
              </div>
            ))}
          </div>

          <div className="grid grid-cols-2 gap-3">
            <Button
              type="button"
              variant="secondary"
              className="bg-secondary text-secondary-foreground hover:bg-secondary/80 hover:text-secondary-foreground h-12 rounded-lg text-base font-medium shadow-none"
              onClick={() => setOpen(false)}
            >
              {t("pages.provider_orders.index.delivery_sheet.cancel")}
            </Button>
            <Button
              type="button"
              className="bg-primary text-primary-foreground hover:bg-primary/90 h-12 rounded-lg text-base font-medium shadow-none"
              onClick={() => {
                onApply(draft)
                setOpen(false)
              }}
            >
              {t("pages.provider_orders.index.delivery_sheet.apply")}
            </Button>
          </div>
        </div>
      </SheetContent>
    </Sheet>
  )
}
