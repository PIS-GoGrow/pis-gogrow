import { Form, Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"
import { useTranslation } from "react-i18next"

import PageContainer from "@/components/page-container"
import { Button } from "@/components/ui/button"
import {
  Field,
  FieldDescription,
  FieldError,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import AppLayout from "@/layouts/app-layout"
import { providerAccount, providerPaymentDetails } from "@/routes"
import type { BreadcrumbItem } from "@/types"
import type { ProviderPaymentDetailsShow } from "@/types/serializers/ProviderPaymentDetailsShow"

export default function PaymentDetails({
  provider,
}: ProviderPaymentDetailsShow) {
  const { t } = useTranslation()
  const page = "pages.provider_payment_details.show"

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.provider_accounts.show.title"),
      href: providerAccount().url,
    },
    { title: t(`${page}.title`), href: providerPaymentDetails.show().url },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t(`${page}.title`)} />

      <PageContainer
        title={t(`${page}.title`)}
        titleVariant="prominent"
        description={t(`${page}.description`)}
        back={
          <Button variant="ghost" size="icon" asChild>
            <Link href={providerAccount().url} aria-label={t(`${page}.back`)}>
              <ArrowLeft aria-hidden="true" />
            </Link>
          </Button>
        }
      >
        <Form
          action={providerPaymentDetails.update()}
          options={{ preserveScroll: true }}
          className="max-w-xl"
        >
          {({ errors, processing }) => (
            <FieldGroup>
              <Field data-invalid={!!errors.bank_name}>
                <FieldLabel htmlFor="bank_name">
                  {t(`${page}.bank_name`)}
                </FieldLabel>
                <Input
                  id="bank_name"
                  name="provider[bank_name]"
                  defaultValue={provider.bank_name ?? ""}
                  placeholder={t(`${page}.bank_name_placeholder`)}
                  aria-invalid={!!errors.bank_name}
                />
                <FieldError>{errors.bank_name}</FieldError>
              </Field>

              <Field data-invalid={!!errors.bank_account_type}>
                <FieldLabel htmlFor="bank_account_type">
                  {t(`${page}.bank_account_type`)}
                </FieldLabel>
                <Select
                  name="provider[bank_account_type]"
                  defaultValue={provider.bank_account_type ?? undefined}
                >
                  <SelectTrigger
                    id="bank_account_type"
                    className="w-full"
                    aria-invalid={!!errors.bank_account_type}
                  >
                    <SelectValue
                      placeholder={t(`${page}.bank_account_type_placeholder`)}
                    />
                  </SelectTrigger>
                  <SelectContent>
                    {(["savings", "checking"] as const).map((type) => (
                      <SelectItem key={type} value={type}>
                        {t(`${page}.bank_account_types.${type}`)}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                <FieldError>{errors.bank_account_type}</FieldError>
              </Field>

              <Field data-invalid={!!errors.bank_account_number}>
                <FieldLabel htmlFor="bank_account_number">
                  {t(`${page}.bank_account_number`)}
                </FieldLabel>
                <Input
                  id="bank_account_number"
                  name="provider[bank_account_number]"
                  inputMode="numeric"
                  defaultValue={provider.bank_account_number ?? ""}
                  aria-invalid={!!errors.bank_account_number}
                />
                <FieldError>{errors.bank_account_number}</FieldError>
              </Field>

              <Field data-invalid={!!errors.bank_account_holder}>
                <FieldLabel htmlFor="bank_account_holder">
                  {t(`${page}.bank_account_holder`)}
                </FieldLabel>
                <Input
                  id="bank_account_holder"
                  name="provider[bank_account_holder]"
                  defaultValue={provider.bank_account_holder ?? ""}
                  aria-invalid={!!errors.bank_account_holder}
                />
                <FieldError>{errors.bank_account_holder}</FieldError>
              </Field>

              <Field data-invalid={!!errors.tax_id}>
                <FieldLabel htmlFor="tax_id">{t(`${page}.tax_id`)}</FieldLabel>
                <Input
                  id="tax_id"
                  name="provider[tax_id]"
                  inputMode="numeric"
                  defaultValue={provider.tax_id ?? ""}
                  aria-invalid={!!errors.tax_id}
                />
                <FieldDescription>
                  {t(`${page}.tax_id_description`)}
                </FieldDescription>
                <FieldError>{errors.tax_id}</FieldError>
              </Field>

              <p className="text-muted-foreground text-sm">
                {t(`${page}.sensitive_notice`)}
              </p>

              <Button type="submit" disabled={processing} className="w-fit">
                {t(`${page}.submit`)}
              </Button>
            </FieldGroup>
          )}
        </Form>
      </PageContainer>
    </AppLayout>
  )
}
