import { Head, Link, router } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import PageContainer from "@/components/page-container"
import { Button } from "@/components/ui/button"
import {
  Field,
  FieldContent,
  FieldDescription,
  FieldLabel,
  FieldTitle,
} from "@/components/ui/field"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import AppLayout from "@/layouts/app-layout"
import { providerAccount, providerDeliveries } from "@/routes"
import type { BreadcrumbItem } from "@/types"
import type { ProviderDeliveriesShow } from "@/types/serializers/ProviderDeliveriesShow"

type DeliveryOption = "office" | "home"

const OPTIONS: DeliveryOption[] = ["office", "home"]

export default function Deliveries({ provider }: ProviderDeliveriesShow) {
  const { t } = useTranslation()
  const [pending, setPending] = useState<DeliveryOption | null>(null)
  const page = "pages.provider_deliveries.show"
  const selected = pending ?? (provider.home_delivery ? "home" : "office")

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.provider_accounts.show.title"),
      href: providerAccount().url,
    },
    { title: t(`${page}.title`), href: providerDeliveries.show().url },
  ]

  const save = (option: DeliveryOption) => {
    setPending(option)
    router.patch(
      providerDeliveries.update().url,
      { home_delivery: option === "home" },
      { preserveScroll: true, onFinish: () => setPending(null) },
    )
  }

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t(`${page}.title`)} />

      <PageContainer
        title={t(`${page}.title`)}
        titleVariant="prominent"
        description={t(`${page}.description`)}
        back={
          <Button variant="ghost" size="icon" asChild>
            <Link href={providerAccount()} aria-label={t(`${page}.back`)}>
              <ArrowLeft aria-hidden="true" />
            </Link>
          </Button>
        }
      >
        <RadioGroup
          value={selected}
          onValueChange={(value) => save(value as DeliveryOption)}
          disabled={pending !== null}
          aria-label={t(`${page}.title`)}
          className="gap-3"
        >
          {OPTIONS.map((option) => (
            <FieldLabel key={option} htmlFor={`delivery-${option}`}>
              <Field orientation="horizontal">
                <RadioGroupItem value={option} id={`delivery-${option}`} />
                <FieldContent>
                  <FieldTitle>{t(`${page}.${option}.title`)}</FieldTitle>
                  <FieldDescription>
                    {t(`${page}.${option}.description`)}
                  </FieldDescription>
                </FieldContent>
              </Field>
            </FieldLabel>
          ))}
        </RadioGroup>
      </PageContainer>
    </AppLayout>
  )
}
