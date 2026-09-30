import { useTranslation } from "react-i18next"

import { Checkbox } from "@/components/ui/checkbox"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"

export interface OptionGroup {
  id: number
  name: string
  options: string[]
  limit: number
}

interface OptionChoicesProps {
  group: OptionGroup
  values: string[]
  setValues: (values: string[]) => void
}

export default function OptionChoices({
  group,
  values,
  setValues,
}: OptionChoicesProps) {
  const { t } = useTranslation()

  return (
    <section className="border-border border-b py-5">
      <h2 className="text-xs font-semibold">
        {t("pages.consumer_dashboard.options.choose", { name: group.name })}
      </h2>
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
              <RadioGroupItem value={option} aria-label={option} />
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
