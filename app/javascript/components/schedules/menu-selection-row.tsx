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
    <div className="flex items-center gap-3 border-b py-3 last:border-b-0">
      <Checkbox
        id={`menu-${menu.id}`}
        checked={checked}
        onCheckedChange={() => onToggle(menu.id)}
      />

      <label htmlFor={`menu-${menu.id}`} className="flex-1 cursor-pointer">
        <p className="font-medium">{menu.name}</p>
        <p className="text-sm text-muted-foreground">{menu.price}$</p>
      </label>

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
  )
}
