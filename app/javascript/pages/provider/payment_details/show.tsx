import { Form, Head, Link } from "@inertiajs/react"
import { ChevronLeft } from "lucide-react"
import { useTranslation } from "react-i18next"

import PageContainer from "@/components/page-container"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import {
  Field,
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
import { Spinner } from "@/components/ui/spinner"
import { Textarea } from "@/components/ui/textarea"
import AppLayout from "@/layouts/app-layout"
import { providerAccount, providerPaymentDetails } from "@/routes"
import type { BreadcrumbItem } from "@/types"
import type { ProviderPaymentDetailsShow } from "@/types/serializers/ProviderPaymentDetailsShow"

interface AccountDetailSection {
  title: string
  lines: string[]
}

function accountDetailSections(
  details: string,
  bankName: string,
): AccountDetailSection[] {
  return details
    .trim()
    .split(/\n\s*\n/)
    .map((block) => {
      const lines = block
        .split("\n")
        .map((line) => line.trim())
        .filter(Boolean)
      const firstLine = lines[0] ?? bankName
      const hasTransferTitle = /^transferencias\b/i.test(firstLine)

      return {
        title: hasTransferTitle ? firstLine : bankName,
        lines: (hasTransferTitle ? lines.slice(1) : lines)
          .filter((line) => !/^moneda\s*:/i.test(line))
          .map((line) => line.replace(/^cuenta\s*:/i, "Nº de cuenta:")),
      }
    })
}

export default function PaymentDetails({
  provider,
  bank_names,
  editing,
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
        description={t(
          `${page}.${editing ? "description" : "consultation_description"}`,
        )}
        back={
          <Button variant="ghost" size="icon" asChild>
            <Link href={providerAccount()} aria-label={t(`${page}.back`)}>
              <ChevronLeft aria-hidden="true" />
            </Link>
          </Button>
        }
      >
        {editing ? (
          <Form
            action={providerPaymentDetails.update()}
            options={{ preserveScroll: true }}
            className="max-w-xl"
            noValidate
          >
            {({ errors, processing }) => (
              <FieldGroup>
                <Field data-invalid={!!errors.bank_name}>
                  <FieldLabel htmlFor="bank_name">
                    {t(`${page}.bank_name`)}
                  </FieldLabel>
                  <Select
                    name="provider[bank_name]"
                    defaultValue={provider.bank_name ?? undefined}
                  >
                    <SelectTrigger
                      id="bank_name"
                      className="w-full"
                      aria-invalid={!!errors.bank_name}
                    >
                      <SelectValue
                        placeholder={t(`${page}.bank_name_placeholder`)}
                      />
                    </SelectTrigger>
                    <SelectContent>
                      {bank_names.map((bankName) => (
                        <SelectItem key={bankName} value={bankName}>
                          {bankName}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  <FieldError>{errors.bank_name}</FieldError>
                </Field>

                <Field data-invalid={!!errors.bank_account_details}>
                  <FieldLabel htmlFor="bank_account_details">
                    {t(`${page}.bank_account_details`)}
                  </FieldLabel>
                  <Textarea
                    id="bank_account_details"
                    name="provider[bank_account_details]"
                    defaultValue={provider.bank_account_details ?? ""}
                    placeholder={t(`${page}.bank_account_details_placeholder`)}
                    className="min-h-36"
                    aria-invalid={!!errors.bank_account_details}
                  />
                  <FieldError>{errors.bank_account_details}</FieldError>
                </Field>

                <Field data-invalid={!!errors.beneficiary}>
                  <FieldLabel htmlFor="beneficiary">
                    {t(`${page}.beneficiary`)}
                  </FieldLabel>
                  <Input
                    id="beneficiary"
                    name="provider[beneficiary]"
                    defaultValue={provider.beneficiary ?? ""}
                    aria-invalid={!!errors.beneficiary}
                  />
                  <FieldError>{errors.beneficiary}</FieldError>
                </Field>

                <div className="flex flex-wrap gap-2">
                  <Button type="submit" disabled={processing}>
                    {processing && <Spinner />}
                    {t(`${page}.submit`)}
                  </Button>
                  {provider.bank_name &&
                    provider.bank_account_details &&
                    provider.beneficiary && (
                      <Button variant="outline" asChild>
                        <Link href={providerPaymentDetails.show()}>
                          {t(`${page}.cancel`)}
                        </Link>
                      </Button>
                    )}
                </div>
              </FieldGroup>
            )}
          </Form>
        ) : (
          <div className="max-w-xl pb-16 md:pb-0">
            <Card className="gap-0 rounded-md py-0 shadow-none">
              {accountDetailSections(
                provider.bank_account_details ?? "",
                provider.bank_name ?? "",
              ).map((section, index) => (
                <section
                  key={`${section.title}-${index}`}
                  className="space-y-1 px-3 py-3 not-first:border-t"
                >
                  <h3 className="text-sm font-semibold">{section.title}</h3>
                  <div className="text-muted-foreground space-y-0.5 text-xs">
                    {section.lines.map((line, lineIndex) => (
                      <p key={`${line}-${lineIndex}`}>{line}</p>
                    ))}
                    <p>
                      {t(`${page}.beneficiary_value`, {
                        beneficiary: provider.beneficiary,
                      })}
                    </p>
                  </div>
                </section>
              ))}
            </Card>

            <div className="fixed right-5 bottom-[92px] left-5 z-20 md:static md:mt-6">
              <Button className="w-full md:w-auto" asChild>
                <Link
                  href={providerPaymentDetails.show({ query: { edit: true } })}
                >
                  {t(`${page}.edit`)}
                </Link>
              </Button>
            </div>
          </div>
        )}
      </PageContainer>
    </AppLayout>
  )
}
