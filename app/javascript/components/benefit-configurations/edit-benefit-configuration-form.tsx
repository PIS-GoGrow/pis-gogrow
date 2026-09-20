import { useForm } from "@inertiajs/react"
import { TriangleAlert } from "lucide-react"
import { useTranslation } from "react-i18next"

import { Alert, AlertDescription } from "@/components/ui/alert"
import { Button } from "@/components/ui/button"
import {
  Field,
  FieldError,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { adminBenefitConfigurations } from "@/routes"

interface EditBenefitConfigurationFormProps {
  defaultValues: {
    subsidy_percentage: number | ""
    max_voucher_price: number | ""
    monthly_voucher_limit: number | ""
  }
  onCancel: () => void
  onSuccess: () => void
}

export default function EditBenefitConfigurationForm({
  defaultValues,
  onCancel,
  onSuccess,
}: EditBenefitConfigurationFormProps) {
  const { t } = useTranslation()

  const { data, setData, post, processing, errors, clearErrors } = useForm({
    subsidy_percentage: defaultValues.subsidy_percentage,
    max_voucher_price: defaultValues.max_voucher_price,
    monthly_voucher_limit: defaultValues.monthly_voucher_limit,
  })

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault()

    post(adminBenefitConfigurations.create().url, {
      preserveScroll: true,
      onSuccess: () => onSuccess(),
    })
  }

  return (
    <form onSubmit={handleSubmit}>
      <FieldGroup>
        <Field data-invalid={!!errors.subsidy_percentage}>
          <FieldLabel htmlFor="subsidy_percentage">
            {t(
              "pages.admin.benefit_configurations.index.edit.subsidy_percentage",
            )}
          </FieldLabel>
          <Input
            id="subsidy_percentage"
            name="subsidy_percentage"
            type="number"
            min="0"
            max="100"
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
          <FieldError
            errors={errors.subsidy_percentage?.map((message) => ({
              message,
            }))}
          />
        </Field>

        <Field data-invalid={!!errors.max_voucher_price}>
          <FieldLabel htmlFor="max_voucher_price">
            {t(
              "pages.admin.benefit_configurations.index.edit.max_voucher_price",
            )}
          </FieldLabel>
          <Input
            id="max_voucher_price"
            name="max_voucher_price"
            type="number"
            min="0.01"
            step="0.01"
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
          <FieldError
            errors={errors.max_voucher_price?.map((message) => ({
              message,
            }))}
          />
        </Field>

        <Field data-invalid={!!errors.monthly_voucher_limit}>
          <FieldLabel htmlFor="monthly_voucher_limit">
            {t(
              "pages.admin.benefit_configurations.index.edit.monthly_voucher_limit",
            )}
          </FieldLabel>
          <Input
            id="monthly_voucher_limit"
            name="monthly_voucher_limit"
            type="number"
            min="0"
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
          <FieldError
            errors={errors.monthly_voucher_limit?.map((message) => ({
              message,
            }))}
          />
        </Field>

        <Alert>
          <TriangleAlert />
          <AlertDescription>
            {t("pages.admin.benefit_configurations.index.edit.notice")}
          </AlertDescription>
        </Alert>

        <div className="flex justify-end gap-2">
          <Button type="button" variant="outline" onClick={onCancel}>
            {t("pages.admin.benefit_configurations.index.edit.cancel")}
          </Button>
          <Button type="submit" disabled={processing}>
            {t("pages.admin.benefit_configurations.index.edit.submit")}
          </Button>
        </div>
      </FieldGroup>
    </form>
  )
}
