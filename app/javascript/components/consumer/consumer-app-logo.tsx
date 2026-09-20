import { ServingFoodIcon } from "@hugeicons/core-free-icons"
import { HugeiconsIcon } from "@hugeicons/react"

export function ConsumerAppLogo() {
  return (
    <>
      <div className="flex aspect-square size-8 items-center justify-center rounded-md bg-black text-white">
        <HugeiconsIcon
          icon={ServingFoodIcon}
          size={20}
          strokeWidth={1.8}
          aria-hidden="true"
        />
      </div>
      <div className="ml-1 grid flex-1 text-left text-sm">
        <span className="mb-0.5 truncate leading-tight font-semibold">
          Viandas GoGrow
        </span>
      </div>
    </>
  )
}
