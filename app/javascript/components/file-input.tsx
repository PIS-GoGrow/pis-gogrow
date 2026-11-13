import type { ComponentProps } from "react"
import { useTranslation } from "react-i18next"

import { cn } from "@/lib/utils"

interface FileInputProps extends Omit<ComponentProps<"input">, "type"> {
  fileName?: string
}

export function FileInput({ fileName, className, ...props }: FileInputProps) {
  const { t } = useTranslation()

  return (
    <label
      className={cn(
        "bg-background focus-within:border-ring focus-within:ring-ring/50 has-[[aria-invalid=true]]:border-destructive flex h-10 min-w-0 cursor-pointer items-center gap-3 rounded-md border px-3 text-sm focus-within:ring-[3px] has-[:disabled]:pointer-events-none has-[:disabled]:opacity-50",
        className,
      )}
    >
      <span className="shrink-0 font-medium">
        {t("components.file_input.select")}
      </span>
      <span className="text-muted-foreground min-w-0 truncate">
        {fileName ?? t("components.file_input.empty")}
      </span>
      <input type="file" className="sr-only" {...props} />
    </label>
  )
}
