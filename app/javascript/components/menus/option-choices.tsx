import { useTranslation } from "react-i18next"

import { Checkbox } from "@/components/ui/checkbox"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"

export interface OptionGroup {
  id: number
  name: string
  options: string[]
  limit: number
  required: boolean
}

interface OptionChoicesProps {
  group: OptionGroup
  values: string[]
  setValues: (values: string[]) => void
}

const neutralName = (name: string) => {
  const lower = name.toLocaleLowerCase("es")

  if (lower.endsWith("s")) return lower

  return `${lower}/${/[aeiouáéíóú]$/.test(lower) ? "s" : "es"}`
}

export default function OptionChoices({
  group,
  values,
  setValues,
}: OptionChoicesProps) {
  const { t } = useTranslation()

  return (
    <section className="border-border border-b py-5">
      <div className="flex items-baseline justify-between gap-2">
        <h2 className="text-xs font-semibold">
          {t("pages.consumer_dashboard.options.choose", {
            name: neutralName(group.name),
          })}
        </h2>
        <span className="text-muted-foreground shrink-0 text-[10px]">
          {t(
            group.required
              ? "pages.consumer_dashboard.options.required"
              : "pages.consumer_dashboard.options.optional",
          )}
        </span>
      </div>
      {group.limit > 1 && (
        <p className="text-muted-foreground mt-1 text-[10px]">
          {t("pages.consumer_dashboard.options.limit", { count: group.limit })}
        </p>
      )}

      {group.limit === 1 ? (
        <RadioGroup
          value={values[0] ?? ""}
          onValueChange={(value) => setValues([value])}
          className="mt-3 space-y-2"
        >
          {group.options.map((option) => (
            <label
              key={option}
              className="flex cursor-pointer items-center gap-2 text-xs"
            >
              <RadioGroupItem
                value={option}
                aria-label={option}
                // Radix no destilda un radio: volver a tocar la opción elegida
                // la quita.
                onClick={() => {
                  if (values[0] === option) setValues([])
                }}
              />
              {option}
            </label>
          ))}
        </RadioGroup>
      ) : (
        <div className="mt-3 space-y-2">
          {group.options.map((option) => {
            const checked = values.includes(option)

            return (
              <label
                key={option}
                className="flex cursor-pointer items-center gap-2 text-xs"
              >
                <Checkbox
                  checked={checked}
                  // Al llegar al límite se bloquean las que no están elegidas,
                  // en lugar de descartar el click sin explicar por qué.
                  disabled={!checked && values.length >= group.limit}
                  onCheckedChange={() =>
                    setValues(
                      checked
                        ? values.filter((value) => value !== option)
                        : [...values, option],
                    )
                  }
                  aria-label={option}
                />
                {option}
              </label>
            )
          })}
        </div>
      )}
    </section>
  )
}
