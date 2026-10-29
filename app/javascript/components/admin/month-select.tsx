import { useTranslation } from "react-i18next"

import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { cn } from "@/lib/utils"

interface MonthSelectProps {
  value: string
  currentMonth: string
  months: { key: string; label: string }[]
  onValueChange: (key: string) => void
  label: string
  className?: string
  compactMenu?: boolean
}

// El selector de mes de las tarjetas de consumo de RR. HH. (Inicio y Pagos).
// Las claves son AAAA-MM y el mes actual se lee "Este mes".
export default function MonthSelect({
  value,
  currentMonth,
  months,
  onValueChange,
  label,
  className,
  compactMenu = false,
}: MonthSelectProps) {
  const { t } = useTranslation()

  return (
    <Select value={value} onValueChange={onValueChange}>
      <SelectTrigger
        size="sm"
        aria-label={label}
        className={cn(
          "bg-background dark:bg-background text-muted-foreground rounded-full border-none shadow-none",
          className,
        )}
      >
        <SelectValue />
      </SelectTrigger>
      <SelectContent
        align="end"
        position={compactMenu ? "popper" : undefined}
        sideOffset={compactMenu ? 4 : undefined}
        collisionPadding={
          compactMenu ? { top: 8, right: 8, bottom: 72, left: 8 } : undefined
        }
        className={
          compactMenu
            ? "max-h-[min(15rem,var(--radix-select-content-available-height))] [&_[data-radix-select-viewport]]:h-auto [&_[data-radix-select-viewport]]:max-h-52 [&_[data-radix-select-viewport]]:min-h-0 [&_[data-radix-select-viewport]]:overscroll-contain"
            : undefined
        }
      >
        {months.map((option) => (
          <SelectItem key={option.key} value={option.key}>
            {option.key === currentMonth
              ? t("components.month_select.this_month")
              : option.label}
          </SelectItem>
        ))}
      </SelectContent>
    </Select>
  )
}
