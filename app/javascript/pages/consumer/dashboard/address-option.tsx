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
        "border-border bg-card flex min-h-[66px] cursor-pointer items-center gap-3 rounded-[10px] border p-3",
        selected && "border-primary bg-muted",
        disabled && "cursor-not-allowed opacity-50",
      )}
    >
      <RadioGroupItem
        value={option.address}
        disabled={disabled}
        className="border-input bg-background text-primary data-[state=checked]:border-primary data-[state=checked]:bg-background shadow-none"
      />
      <div className="flex flex-col gap-1 text-sm">
        <span className="text-foreground font-medium">{option.label}</span>
        <span className="text-muted-foreground text-xs leading-4">
          {option.address}
        </span>
      </div>
    </label>
  )
}
