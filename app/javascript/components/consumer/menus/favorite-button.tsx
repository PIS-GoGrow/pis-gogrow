import { Star } from "lucide-react"

import { Button } from "@/components/ui/button"
import { cn } from "@/lib/utils"

interface Props {
  active: boolean
  label: string
  onToggle: () => void
}

export default function FavoriteButton({ active, label, onToggle }: Props) {
  return (
    <Button
      type="button"
      variant="ghost"
      size="icon"
      aria-label={label}
      aria-pressed={active}
      onClick={(event) => {
        event.stopPropagation()
        onToggle()
      }}
      className="size-8 shrink-0 rounded-full"
    >
      <Star
        aria-hidden="true"
        className={cn("size-4", active && "fill-amber-400 text-amber-400")}
      />
    </Button>
  )
}
