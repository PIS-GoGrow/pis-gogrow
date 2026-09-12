import { UtensilsCrossed } from "lucide-react"

import { Badge } from "@/components/ui/badge"
import { Checkbox } from "@/components/ui/checkbox"
import { Field, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import type { Menu } from "@/types"

interface MenuSelectionRowProps {
  menu: Menu
  checked: boolean
  amount: string
  onToggle: (menuId: number) => void
  onAmountChange: (menuId: number, value: string) => void
}

export default function MenuSelectionRow({
  menu,
  checked,
  amount,
  onToggle,
  onAmountChange,
}: MenuSelectionRowProps) {
  return (
    <div className="flex flex-col gap-3 rounded-xl border p-4">
      <div className="flex items-start gap-3">
        <div className="flex size-10 shrink-0 items-center justify-center rounded-md bg-muted">
          <UtensilsCrossed className="size-5 text-muted-foreground" />
        </div>

        <div className="flex-1">
          <Badge variant={checked ? "default" : "outline"} className="mb-1">
            {checked ? "Seleccionado" : "Sin seleccionar"}
          </Badge>
          <p className="font-medium">{menu.name}</p>
          <p className="text-sm text-muted-foreground">{menu.description}</p>
        </div>

        <Checkbox
          checked={checked}
          onCheckedChange={() => onToggle(menu.id)}
          aria-label={`Seleccionar ${menu.name}`}
        />
      </div>

      <div className="flex items-center justify-between">
        <p className="font-semibold">{menu.price}$</p>

        <Field className="w-28">
          <FieldLabel htmlFor={`amount-${menu.id}`} className="sr-only">
            Stock
          </FieldLabel>
          <Input
            id={`amount-${menu.id}`}
            type="number"
            min="1"
            step="1"
            placeholder="Stock"
            disabled={!checked}
            value={amount}
            onChange={(e) => onAmountChange(menu.id, e.target.value)}
          />
        </Field>
      </div>
    </div>
  )
}
