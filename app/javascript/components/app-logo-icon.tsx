import { ServingFoodIcon } from "@hugeicons/core-free-icons"
import { HugeiconsIcon } from "@hugeicons/react"
import type { ComponentProps } from "react"

interface AppLogoIconProps extends Omit<ComponentProps<"svg">, "ref"> {
  size?: number
  strokeWidth?: number
}

export default function AppLogoIcon({
  className,
  size = 24,
  strokeWidth = 1.8,
  ...props
}: AppLogoIconProps) {
  return (
    <HugeiconsIcon
      icon={ServingFoodIcon}
      size={size}
      strokeWidth={strokeWidth}
      className={className}
      aria-hidden="true"
      {...props}
    />
  )
}
