import { useTranslation } from "react-i18next"

import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"

interface MonthSelectProps {
  value: string
  currentMonth: string
  months: { key: string; label: string }[]
  onValueChange: (key: string) => void
  label: string
}

// El selector de mes de las tarjetas de consumo de RR. HH. (Inicio y Pagos).
// Las claves son AAAA-MM y el mes actual se lee "Este mes".
export default function MonthSelect({
  value,
  currentMonth,
  months,
  onValueChange,
  label,
}: MonthSelectProps) {
  const { t } = useTranslation()

  return (
    <Select value={value} onValueChange={onValueChange}>
      <SelectTrigger
        size="sm"
        aria-label={label}
        className="bg-background dark:bg-background text-muted-foreground rounded-full border-none shadow-none"
      >
        <SelectValue />
      </SelectTrigger>
      <SelectContent align="end">
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
