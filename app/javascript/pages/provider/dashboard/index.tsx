import { Form, Head } from "@inertiajs/react"
import { useTranslation } from "react-i18next"

import PageContainer from "@/components/page-container"
import { Button } from "@/components/ui/button"
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import {
  Field,
  FieldDescription,
  FieldError,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import AppLayout from "@/layouts/app-layout"
import { providerDashboard, providerOrderDeadline } from "@/routes"
import type { BreadcrumbItem } from "@/types"
import type { ProviderDashboardIndex } from "@/types/serializers/ProviderDashboardIndex"

type Props = ProviderDashboardIndex

export default function ProviderDashboard({ provider }: Props) {
  const { t } = useTranslation()

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.provider_dashboard.index.title"),
      href: providerDashboard.index().url,
    },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t("pages.provider_dashboard.index.title")} />

      <PageContainer
        eyebrow={t("pages.provider_dashboard.index.eyebrow")}
        title={t("pages.provider_dashboard.index.title")}
        description={t("pages.provider_dashboard.index.description")}
      >
        <div className="grid gap-4 md:grid-cols-2">
          <Card>
            <CardHeader>
              <CardTitle>
                {t("pages.provider_dashboard.index.order_deadline.title")}
              </CardTitle>
              <CardDescription>
                {t("pages.provider_dashboard.index.order_deadline.description")}
              </CardDescription>
            </CardHeader>

            <CardContent>
              <Form
                method="patch"
                action={providerOrderDeadline().url}
                options={{ preserveScroll: true }}
              >
                {({ errors, processing }) => (
                  <FieldGroup>
                    <Field>
                      <FieldLabel htmlFor="order_deadline">
                        {t("pages.provider_dashboard.index.order_deadline.label")}
                      </FieldLabel>
                      <Input
                        id="order_deadline"
                        name="order_deadline"
                        type="time"
                        defaultValue={provider.order_deadline ?? ""}
                        aria-invalid={!!errors.order_deadline}
                      />
                      <FieldDescription>
                        {t("pages.provider_dashboard.index.order_deadline.help")}
                      </FieldDescription>
                      <FieldError
                        errors={errors.order_deadline?.map((message) => ({
                          message,
                        }))}
                      />
                    </Field>

                    <Button type="submit" disabled={processing}>
                      {t("common.save")}
                    </Button>
                  </FieldGroup>
                )}
              </Form>
            </CardContent>
          </Card>
        </div>
      </PageContainer>
    </AppLayout>
  )
}
