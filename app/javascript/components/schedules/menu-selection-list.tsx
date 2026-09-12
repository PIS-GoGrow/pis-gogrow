import MenuSelectionRow from "@/components/schedules/menu-selection-row"
import { Card, CardContent } from "@/components/ui/card"
import type { Menu } from "@/types"

interface MenuSelectionListProps {
  menus: Menu[]
  selection: Record<number, string>
  onToggle: (menuId: number) => void
  onAmountChange: (menuId: number, value: string) => void
}

export default function MenuSelectionList({
  menus,
  selection,
  onToggle,
  onAmountChange,
}: MenuSelectionListProps) {
  return (
    <Card>
      <CardContent>
        {menus.map((menu) => (
          <MenuSelectionRow
            key={menu.id}
            menu={menu}
            checked={menu.id in selection}
            amount={selection[menu.id] ?? ""}
            onToggle={onToggle}
            onAmountChange={onAmountChange}
          />
        ))}
      </CardContent>
    </Card>
  )
}