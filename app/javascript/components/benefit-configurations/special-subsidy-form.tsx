import { useForm } from "@inertiajs/react"
import { XIcon } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import {
  Field,
  FieldDescription,
  FieldError,
  FieldGroup,
  FieldLabel,
  FieldLegend,
  FieldSet,
} from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { Spinner } from "@/components/ui/spinner"
import { adminSpecialSubsidies } from "@/routes"
import type { Employee, SpecialSubsidy } from "@/types/serializers"

type Condition = NonNullable<SpecialSubsidy["condition"]>

interface SpecialSubsidyFormData {
  name: string
  subsidy_percentage: number | ""
  applies_to_all: boolean
  consumer_ids: number[]
  condition: {
    type: Condition["type"] | ""
    min_years: number | ""
    limit: number | ""
    validity_amount: number | ""
    validity_unit: NonNullable<Condition["validity_unit"]>
    effective_from: string
  }
}

interface SpecialSubsidyFormProps {
  subsidy?: SpecialSubsidy
  employees: Employee[]
  onCancel: () => void
  onSuccess: () => void
}

function toNumber(value: string): number | "" {
  return value === "" ? "" : Number(value)
}

function isPositiveInteger(value: number | ""): value is number {
  return value !== "" && Number.isInteger(value) && value > 0
}

function normalize(text: string) {
  return text
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "")
    .toLowerCase()
}

export default function SpecialSubsidyForm({
  subsidy,
  employees,
  onCancel,
  onSuccess,
}: SpecialSubsidyFormProps) {
  const { t } = useTranslation()
  const [query, setQuery] = useState("")

  const form = useForm<SpecialSubsidyFormData>({
    name: subsidy?.name ?? "",
    subsidy_percentage: subsidy?.subsidy_percentage ?? "",
    applies_to_all: subsidy?.applies_to_all ?? true,
    consumer_ids: subsidy?.consumer_ids ?? [],
    condition: {
      type: subsidy?.condition?.type ?? "",
      min_years: subsidy?.condition?.min_years ?? "",
      limit: subsidy?.condition?.limit ?? "",
      validity_amount: subsidy?.condition?.validity_amount ?? "",
      validity_unit: subsidy?.condition?.validity_unit ?? "days",
      effective_from: subsidy?.condition?.effective_from ?? "",
    },
  })

  const { data, setData, post, patch, processing, transform } = form
  const { condition } = data
  const now = new Date()
  const today = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}`
  const originalEffectiveFrom = subsidy?.condition?.effective_from ?? ""
  // El servidor devuelve los errores con los nombres de los campos del formulario,
  // incluidos los de la condiciÃ³n (limit, validity_amountâ€¦), que acÃ¡ van anidados.
  const errors = form.errors as Partial<Record<string, string | string[]>>

  function fieldErrors(key: string) {
    const messages = errors[key]
    return messages
      ? [messages].flat().map((message) => ({ message }))
      : undefined
  }

  function setCondition(changes: Partial<typeof condition>) {
    setData("condition", { ...condition, ...changes })
  }

  const conditionIsValid =
    condition.type === "seniority"
      ? isPositiveInteger(condition.min_years)
      : condition.type !== "" &&
        isPositiveInteger(condition.limit) &&
        isPositiveInteger(condition.validity_amount) &&
        (condition.type !== "gift" ||
          (condition.effective_from !== "" &&
            (condition.effective_from >= today ||
              condition.effective_from === originalEffectiveFrom)))

  const isValid =
    data.name.trim() !== "" &&
    isPositiveInteger(data.subsidy_percentage) &&
    data.subsidy_percentage <= 100 &&
    (data.applies_to_all || data.consumer_ids.length > 0) &&
    conditionIsValid

  const selectedEmployees = employees.filter((employee) =>
    data.consumer_ids.includes(employee.id),
  )
  const matchingEmployees =
    query.trim() === ""
      ? []
      : employees.filter(
          (employee) =>
            !data.consumer_ids.includes(employee.id) &&
            normalize(employee.name).includes(normalize(query.trim())),
        )

  function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()

    transform((current) => ({ special_subsidy: current }))
    const options = { preserveScroll: true, onSuccess: () => onSuccess() }

    if (subsidy) {
      patch(adminSpecialSubsidies.update(subsidy.id).url, options)
    } else {
      post(adminSpecialSubsidies.create().url, options)
    }
  }

  const limitAndValidity = (
    <>
      <Field orientation="horizontal" data-invalid={!!errors.limit}>
        <FieldLabel htmlFor="condition_limit" className="font-normal">
          {t(
            "pages.admin.benefit_configurations.index.special.form.limit_prefix",
          )}
        </FieldLabel>
        <Input
          id="condition_limit"
          name="limit"
          type="number"
          min="1"
          className="w-20"
          value={condition.limit}
          aria-invalid={!!errors.limit}
          onChange={(event) =>
            setCondition({ limit: toNumber(event.target.value) })
          }
        />
        <span className="text-muted-foreground text-sm">
          {t(
            "pages.admin.benefit_configurations.index.special.form.limit_suffix",
          )}
        </span>
      </Field>
      <FieldError errors={fieldErrors("limit")} />

      <Field orientation="horizontal" data-invalid={!!errors.validity_amount}>
        <FieldLabel htmlFor="condition_validity_amount" className="font-normal">
          {t("pages.admin.benefit_configurations.index.special.form.validity")}
        </FieldLabel>
        <Input
          id="condition_validity_amount"
          name="validity_amount"
          type="number"
          min="1"
          className="w-20"
          value={condition.validity_amount}
          aria-invalid={!!errors.validity_amount}
          onChange={(event) =>
            setCondition({ validity_amount: toNumber(event.target.value) })
          }
        />
        <Select
          name="validity_unit"
          value={condition.validity_unit}
          onValueChange={(value) =>
            setCondition({
              validity_unit: value as typeof condition.validity_unit,
            })
          }
        >
          <SelectTrigger
            className="w-32"
            aria-label={t(
              "pages.admin.benefit_configurations.index.special.form.validity_unit",
            )}
          >
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {(["days", "weeks", "months"] as const).map((unit) => (
              <SelectItem key={unit} value={unit}>
                {t(
                  `pages.admin.benefit_configurations.index.special.form.validity_units.${unit}`,
                )}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </Field>
      <FieldError errors={fieldErrors("validity_amount")} />
    </>
  )

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-5">
      <FieldGroup className="gap-5">
        <div className="grid grid-cols-[1fr_auto] gap-3">
          <Field data-invalid={!!errors.name}>
            <FieldLabel htmlFor="special_subsidy_name">
              {t("pages.admin.benefit_configurations.index.special.form.name")}
            </FieldLabel>
            <Input
              id="special_subsidy_name"
              name="name"
              value={data.name}
              placeholder={t(
                "pages.admin.benefit_configurations.index.special.form.name_placeholder",
              )}
              aria-invalid={!!errors.name}
              onChange={(event) => setData("name", event.target.value)}
            />
            <FieldError errors={fieldErrors("name")} />
          </Field>

          <Field data-invalid={!!errors.subsidy_percentage} className="w-28">
            <FieldLabel htmlFor="special_subsidy_percentage">
              {t(
                "pages.admin.benefit_configurations.index.special.form.subsidy_percentage",
              )}
            </FieldLabel>
            <Input
              id="special_subsidy_percentage"
              name="subsidy_percentage"
              type="number"
              min="1"
              max="100"
              value={data.subsidy_percentage}
              aria-invalid={!!errors.subsidy_percentage}
              onChange={(event) =>
                setData("subsidy_percentage", toNumber(event.target.value))
              }
            />
            <FieldError errors={fieldErrors("subsidy_percentage")} />
          </Field>
        </div>

        <FieldSet data-invalid={!!errors.consumer_ids}>
          <FieldLegend variant="label">
            {t(
              "pages.admin.benefit_configurations.index.special.form.applies_to",
            )}
          </FieldLegend>
          <RadioGroup
            name="applies_to_all"
            value={data.applies_to_all ? "all" : "selection"}
            onValueChange={(value) =>
              setData("applies_to_all", value === "all")
            }
          >
            <Field orientation="horizontal">
              <RadioGroupItem value="all" id="applies_to_all" />
              <FieldLabel htmlFor="applies_to_all" className="font-normal">
                {t(
                  "pages.admin.benefit_configurations.index.special.form.all_employees",
                )}
              </FieldLabel>
            </Field>
            <Field orientation="horizontal">
              <RadioGroupItem value="selection" id="applies_to_selection" />
              <FieldLabel
                htmlFor="applies_to_selection"
                className="font-normal"
              >
                {t(
                  "pages.admin.benefit_configurations.index.special.form.select_employees",
                )}
              </FieldLabel>
            </Field>
          </RadioGroup>

          {!data.applies_to_all && (
            <div className="flex flex-col gap-2">
              <Input
                type="search"
                name="employee_search"
                aria-label={t(
                  "pages.admin.benefit_configurations.index.special.form.search_employee",
                )}
                placeholder={t(
                  "pages.admin.benefit_configurations.index.special.form.search_employee",
                )}
                value={query}
                onChange={(event) => setQuery(event.target.value)}
              />

              {query.trim() !== "" && (
                <div className="flex flex-col rounded-md border p-1">
                  {matchingEmployees.length > 0 ? (
                    matchingEmployees.map((employee) => (
                      <Button
                        key={employee.id}
                        type="button"
                        variant="ghost"
                        size="sm"
                        className="justify-start"
                        onClick={() => {
                          setData("consumer_ids", [
                            ...data.consumer_ids,
                            employee.id,
                          ])
                          setQuery("")
                        }}
                      >
                        {employee.name}
                      </Button>
                    ))
                  ) : (
                    <p className="text-muted-foreground px-2 py-1.5 text-sm">
                      {t(
                        "pages.admin.benefit_configurations.index.special.form.no_employees_found",
                      )}
                    </p>
                  )}
                </div>
              )}

              {selectedEmployees.length > 0 && (
                <ul
                  className="flex flex-wrap gap-2"
                  aria-label={t(
                    "pages.admin.benefit_configurations.index.special.form.selected_employees",
                  )}
                >
                  {selectedEmployees.map((employee) => (
                    <li key={employee.id}>
                      <Badge variant="secondary" className="gap-0.5 pr-0.5">
                        {employee.short_name}
                        <Button
                          type="button"
                          variant="ghost"
                          size="icon-xs"
                          className="size-4"
                          aria-label={t(
                            "pages.admin.benefit_configurations.index.special.form.remove_employee",
                            { name: employee.name },
                          )}
                          onClick={() =>
                            setData(
                              "consumer_ids",
                              data.consumer_ids.filter(
                                (id) => id !== employee.id,
                              ),
                            )
                          }
                        >
                          <XIcon aria-hidden="true" />
                        </Button>
                      </Badge>
                    </li>
                  ))}
                </ul>
              )}
            </div>
          )}
          <FieldError errors={fieldErrors("consumer_ids")} />
        </FieldSet>

        <FieldSet data-invalid={!!errors.condition_type}>
          <FieldLegend variant="label">
            {t(
              "pages.admin.benefit_configurations.index.special.form.condition",
            )}
          </FieldLegend>
          <Select
            name="condition_type"
            value={condition.type}
            onValueChange={(value) =>
              setCondition({ type: value as typeof condition.type })
            }
          >
            <SelectTrigger
              className="w-full"
              aria-label={t(
                "pages.admin.benefit_configurations.index.special.condition",
              )}
              aria-invalid={!!errors.condition_type}
            >
              <SelectValue
                placeholder={t(
                  "pages.admin.benefit_configurations.index.special.form.condition_placeholder",
                )}
              />
            </SelectTrigger>
            <SelectContent>
              {(["seniority", "birthday", "onboarding", "gift"] as const).map(
                (type) => (
                  <SelectItem key={type} value={type}>
                    {t(
                      `pages.admin.benefit_configurations.index.special.conditions.${type}`,
                    )}
                  </SelectItem>
                ),
              )}
            </SelectContent>
          </Select>
          <FieldError errors={fieldErrors("condition_type")} />

          {condition.type === "seniority" && (
            <>
              <Field orientation="horizontal" data-invalid={!!errors.min_years}>
                <FieldLabel
                  htmlFor="condition_min_years"
                  className="font-normal"
                >
                  {t(
                    "pages.admin.benefit_configurations.index.special.form.min_years_prefix",
                  )}
                </FieldLabel>
                <Input
                  id="condition_min_years"
                  name="min_years"
                  type="number"
                  min="1"
                  className="w-20"
                  value={condition.min_years}
                  aria-invalid={!!errors.min_years}
                  onChange={(event) =>
                    setCondition({ min_years: toNumber(event.target.value) })
                  }
                />
                <span className="text-muted-foreground text-sm">
                  {t(
                    "pages.admin.benefit_configurations.index.special.form.min_years_suffix",
                  )}
                </span>
              </Field>
              <FieldError errors={fieldErrors("min_years")} />
            </>
          )}

          {(condition.type === "birthday" ||
            condition.type === "onboarding") && (
            <>
              <FieldDescription>
                {t(
                  `pages.admin.benefit_configurations.index.special.form.${condition.type}_help`,
                )}
              </FieldDescription>
              {limitAndValidity}
            </>
          )}

          {condition.type === "gift" && (
            <>
              <Field
                orientation="horizontal"
                data-invalid={!!errors.effective_from}
              >
                <FieldLabel
                  htmlFor="condition_effective_from"
                  className="font-normal"
                >
                  {t(
                    "pages.admin.benefit_configurations.index.special.form.effective_from",
                  )}
                </FieldLabel>
                <Input
                  id="condition_effective_from"
                  name="effective_from"
                  type="date"
                  min={today}
                  className="w-44"
                  value={condition.effective_from}
                  aria-invalid={!!errors.effective_from}
                  onChange={(event) =>
                    setCondition({ effective_from: event.target.value })
                  }
                />
              </Field>
              <FieldError errors={fieldErrors("effective_from")} />
              {limitAndValidity}
            </>
          )}
        </FieldSet>
      </FieldGroup>

      <div className="grid grid-cols-2 gap-3">
        <Button
          type="button"
          variant="outline"
          className="h-12 rounded-lg text-base font-medium"
          onClick={onCancel}
        >
          {t("pages.admin.benefit_configurations.index.special.form.cancel")}
        </Button>
        <Button
          type="submit"
          className="h-12 rounded-lg text-base font-medium"
          disabled={!isValid || processing}
        >
          {processing && <Spinner />}
          {subsidy
            ? t("pages.admin.benefit_configurations.index.special.form.update")
            : t("pages.admin.benefit_configurations.index.special.form.add")}
        </Button>
      </div>
    </form>
  )
}
