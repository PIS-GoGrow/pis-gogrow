import { Star } from "lucide-react"
import { useTranslation } from "react-i18next"

import { cn } from "@/lib/utils"

interface StarRatingProps {
  value: number
  onChange: (value: number) => void
}

const STARS = [1, 2, 3, 4, 5]

export default function StarRating({ value, onChange }: StarRatingProps) {
  const { t } = useTranslation()

  return (
    <div role="radiogroup" className="flex w-full max-w-67 items-center gap-3">
      {STARS.map((star) => (
        <button
          key={star}
          type="button"
          role="radio"
          aria-checked={value === star}
          aria-label={t("pages.reviews.new.star", { count: star })}
          onClick={() => onChange(star)}
          className="focus-visible:ring-ring/50 flex size-11 shrink-0 items-center justify-center rounded-full transition-transform hover:scale-110 focus-visible:ring-[3px] focus-visible:outline-none"
        >
          <Star
            className={cn("size-7", star <= value && "fill-current")}
            aria-hidden="true"
          />
        </button>
      ))}
    </div>
  )
}
