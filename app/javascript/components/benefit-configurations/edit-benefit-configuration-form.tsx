import { useForm } from "@inertiajs/react"
import { AlertCircleIcon, TriangleAlert } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { Button } from "@/components/ui/button"
import {
  Field,
  FieldContent,
  FieldError,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { adminBenefitConfigurations } from "@/routes"
import type { BenefitConfiguration } from "@/types/serializers"

interface EditBenefitConfigurationFormProps {
  defaultValues: {
    subsidy_percentage: number | ""
    max_voucher_price: number | ""
    monthly_voucher_limit: number | ""
  }
  pendingBenefitConfiguration?: BenefitConfiguration
  onCancel: () => void
  onSuccess: () => void
}

export default function EditBenefitConfigurationForm({
  defaultValues,
  pendingBenefitConfiguration,
  onCancel,
  onSuccess,
}: EditBenefitConfigurationFormProps) {
  const { t } = useTranslation()
  const [showPendingConflict, setShowPendingConflict] = useState(false)

  const { data, setData, post, processing, errors, clearErrors, transform } =
    useForm({
      subsidy_percentage: defaultValues.subsidy_percentage,
      max_voucher_price: defaultValues.max_voucher_price,
      monthly_voucher_limit: defaultValues.monthly_voucher_limit,
    })

  function submit(replacePending: boolean) {
    transform((currentData) => ({
      benefit_configuration: {
        subsidy_percentage: currentData.subsidy_percentage,
        max_voucher_price: currentData.max_voucher_price,
        monthly_voucher_limit: currentData.monthly_voucher_limit,
      },
      replace_pending: replacePending,
    }))

    post(adminBenefitConfigurations.create().url, {
      preserveScroll: true,
      onSuccess: () => onSuccess(),
    })
  }

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault()

    // Ya hay un cambio programado para el proximo periodo: en vez de
    // mandar el guardado directo (que el server va a rechazar por la
    // unicidad de effective_from), le preguntamos a RRHH si quiere
    // mantener lo ya programado o reemplazarlo por estos valores nuevos.
    if (pendingBenefitConfiguration) {
      setShowPendingConflict(true)
      return
    }

    submit(false)
  }

  function handleKeepExisting() {
    setShowPendingConflict(false)
    onCancel()
  }

  function handleReplace() {
    setShowPendingConflict(false)
    submit(true)
  }

  return (
    <form onSubmit={handleSubmit}>
      <FieldGroup>
        <Field
          orientation="horizontal"
          data-invalid={!!errors.subsidy_percentage}
        >
          <FieldLabel htmlFor="subsidy_percentage" className="font-normal">
            {t(
              "pages.admin.benefit_configurations.index.current.subsidy_percentage",
            )}
          </FieldLabel>
          <FieldContent className="flex-none">
            <div className="flex items-center gap-2">
              <Input
                id="subsidy_percentage"
                name="subsidy_percentage"
                type="number"
                min="0"
                max="100"
                className="w-24 text-base"
                value={data.subsidy_percentage}
                aria-invalid={!!errors.subsidy_percentage}
                onChange={(e) => {
                  setData(
                    "subsidy_percentage",
                    e.target.value === "" ? "" : Number(e.target.value),
                  )
                  clearErrors("subsidy_percentage")
                }}
              />
              <span className="text-muted-foreground">%</span>
            </div>
            <FieldError
              errors={errors.subsidy_percentage?.map((message) => ({
                message,
              }))}
            />
          </FieldContent>
        </Field>

        <Field
          orientation="horizontal"
          data-invalid={!!errors.max_voucher_price}
        >
          <FieldLabel htmlFor="max_voucher_price" className="font-normal">
            {t(
              "pages.admin.benefit_configurations.index.current.max_voucher_price",
            )}
          </FieldLabel>
          <FieldContent className="flex-none">
            <div className="flex items-center gap-2">
              <span className="text-muted-foreground">≤$</span>
              <Input
                id="max_voucher_price"
                name="max_voucher_price"
                type="number"
                min="0.01"
                step="0.01"
                className="w-24 text-base"
                value={data.max_voucher_price}
                aria-invalid={!!errors.max_voucher_price}
                onChange={(e) => {
                  setData(
                    "max_voucher_price",
                    e.target.value === "" ? "" : Number(e.target.value),
                  )
                  clearErrors("max_voucher_price")
                }}
              />
            </div>
            <FieldError
              errors={errors.max_voucher_price?.map((message) => ({
                message,
              }))}
            />
          </FieldContent>
        </Field>

        <Field
          orientation="horizontal"
          data-invalid={!!errors.monthly_voucher_limit}
        >
          <FieldLabel htmlFor="monthly_voucher_limit" className="font-normal">
            {t(
              "pages.admin.benefit_configurations.index.current.monthly_voucher_limit",
            )}
          </FieldLabel>
          <FieldContent className="flex-none">
            <div className="flex items-center gap-2">
              <Input
                id="monthly_voucher_limit"
                name="monthly_voucher_limit"
                type="number"
                min="0"
                className="w-24 text-base"
                value={data.monthly_voucher_limit}
                aria-invalid={!!errors.monthly_voucher_limit}
                onChange={(e) => {
                  setData(
                    "monthly_voucher_limit",
                    e.target.value === "" ? "" : Number(e.target.value),
                  )
                  clearErrors("monthly_voucher_limit")
                }}
              />
              <span className="text-muted-foreground">
                {t(
                  "pages.admin.benefit_configurations.index.current.monthly_voucher_limit_unit",
                )}
              </span>
            </div>
            <FieldError
              errors={errors.monthly_voucher_limit?.map((message) => ({
                message,
              }))}
            />
          </FieldContent>
        </Field>

        {/* effective_from no es un campo del formulario (se calcula en el
            server), pero puede fallar por unicidad si ya hay un cambio
            pendiente para el proximo periodo -- sin esto el error queda
            invisible para quien lo esta llenando. */}
        <FieldError
          errors={(
            errors as Record<string, string[] | undefined>
          ).effective_from?.map((message) => ({ message }))}
        />

        {showPendingConflict && pendingBenefitConfiguration ? (
          <>
            <Alert>
              <AlertCircleIcon />
              <AlertTitle className="font-bold">
                {t(
                  "pages.admin.benefit_configurations.index.current.pending_conflict.title",
                )}
              </AlertTitle>
              <AlertDescription>
                {t(
                  "pages.admin.benefit_configurations.index.current.pending_conflict.description",
                  {
                    subsidy_percentage:
                      pendingBenefitConfiguration.subsidy_percentage,
                    max_voucher_price:
                      pendingBenefitConfiguration.max_voucher_price,
                    monthly_voucher_limit:
                      pendingBenefitConfiguration.monthly_voucher_limit,
                  },
                )}
              </AlertDescription>
            </Alert>

            <div className="flex justify-end gap-2">
              <Button
                type="button"
                variant="outline"
                onClick={handleKeepExisting}
              >
                {t(
                  "pages.admin.benefit_configurations.index.current.pending_conflict.keep",
                )}
              </Button>
              <Button
                type="button"
                onClick={handleReplace}
                disabled={processing}
              >
                {t(
                  "pages.admin.benefit_configurations.index.current.pending_conflict.replace",
                )}
              </Button>
            </div>
          </>
        ) : (
          <>
            <div className="flex items-center gap-2 text-sm text-amber-600 dark:text-amber-500">
              <TriangleAlert className="size-4 shrink-0" />
              <span>
                {t("pages.admin.benefit_configurations.index.current.notice")}
              </span>
            </div>

            <div className="flex justify-end gap-2">
              <Button type="button" variant="outline" onClick={onCancel}>
                {t("pages.admin.benefit_configurations.index.current.cancel")}
              </Button>
              <Button type="submit" disabled={processing}>
                {t("pages.admin.benefit_configurations.index.current.submit")}
              </Button>
            </div>
          </>
        )}
      </FieldGroup>
    </form>
  )
}
