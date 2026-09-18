import { Minus, Plus } from "lucide-react"

import { Button } from "@/components/ui/button"

interface Props {
  value: number
  min?: number
  max: number
  onChange: (value: number) => void
}

export function QuantityInput({ value, min = 1, max, onChange }: Props) {
  return (
    <div className="bg-secondary text-secondary-foreground flex h-12 items-center rounded-lg">
      <Button
        type="button"
        variant="ghost"
        size="icon"
        aria-label="Quitar uno"
        disabled={value <= min}
        onClick={() => onChange(Math.max(min, value - 1))}
        className="hover:bg-primary hover:text-primary-foreground dark:hover:!bg-primary dark:hover:!text-primary-foreground h-full rounded-r-none"
      >
        <Minus aria-hidden="true" className="size-3" />
      </Button>
      <span className="min-w-6 text-center">{value}</span>
      <Button
        type="button"
        variant="ghost"
        size="icon"
        aria-label="Agregar uno"
        disabled={value >= max}
        onClick={() => onChange(Math.min(max, value + 1))}
        className="hover:bg-primary hover:text-primary-foreground dark:hover:!bg-primary dark:hover:!text-primary-foreground h-full rounded-l-none"
      >
        <Plus aria-hidden="true" className="size-3" />
      </Button>
    </div>
  )
}
