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
        "border-border bg-card flex min-h-[66px] cursor-pointer gap-3 rounded-lg border p-3",
        selected && "border-primary bg-muted",
        disabled && "cursor-not-allowed opacity-50",
      )}
    >
      <RadioGroupItem
        value={option.address}
        disabled={disabled}
        className="border-input bg-background text-primary data-[state=checked]:border-primary data-[state=checked]:bg-background mt-0.5 shadow-none"
      />
      <span className="text-xs">
        <b>{option.label}</b>
        <small className="text-muted-foreground mt-1 block">
          {option.address}
        </small>
      </span>
    </label>
  )
}
