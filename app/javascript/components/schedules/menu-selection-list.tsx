import MenuSelectionRow from "@/components/schedules/menu-selection-row"
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
    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
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
    </div>
  )
}