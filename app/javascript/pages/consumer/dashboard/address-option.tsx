import { RadioGroupItem } from "@/components/ui/radio-group"
import { cn } from "@/lib/utils"

import type { DeliveryAddressOption } from "./consumer-types"

interface Props {
  option: DeliveryAddressOption
  selected: boolean
  disabled?: boolean
}

export function AddressOption({ option, selected, disabled = false }: Props) {
  return (
    <label
      className={cn(
        "flex min-h-[66px] cursor-pointer items-start gap-3 rounded-[10px] border p-3 transition-colors",
        selected
          ? "border-[#171717] bg-[#F5F5F5] dark:border-neutral-200 dark:bg-neutral-800"
          : "border-[#E5E5E5] bg-card dark:border-neutral-700",
        disabled && "cursor-not-allowed opacity-50",
      )}
    >
      <RadioGroupItem
        value={option.address}
        disabled={disabled}
        className="border-input bg-background text-primary data-[state=checked]:border-primary data-[state=checked]:bg-background mt-0.5 shadow-none"
      />
      <span className="text-sm">
        <b className="font-semibold text-[#0A0A0A] dark:text-neutral-100">{option.label}</b>
        <small className="text-muted-foreground mt-0.5 block text-xs">
          {option.address}
        </small>
      </span>
    </label>
  )
}
