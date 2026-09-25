import { Head, usePage } from "@inertiajs/react"
import { AlertCircleIcon, PencilIcon, XIcon } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import EditBenefitConfigurationForm from "@/components/benefit-configurations/edit-benefit-configuration-form"
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { Button } from "@/components/ui/button"
import {
  Card,
  CardAction,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { Empty, EmptyHeader, EmptyTitle } from "@/components/ui/empty"
import AppLayout from "@/layouts/app-layout"
import { adminBenefitConfigurations } from "@/routes"
import type { BreadcrumbItem } from "@/types"
import type { AdminBenefitConfigurationsIndex } from "@/types/serializers"

export default function Index({
  benefit_configurations,
  current_benefit_configuration,
}: AdminBenefitConfigurationsIndex) {
  const { t } = useTranslation()
  const { flash } = usePage()
  const [isEditing, setIsEditing] = useState(false)

  // El cartel de "Tus cambios estan programados" solo se muestra justo
  // despues de programar un cambio (cuando el redirect del create trae un
  // flash.notice), no cada vez que se entra a la pantalla con un cambio
  // pendiente -- asi lo pidio Fran. flash.notice desaparece solo en la
  // proxima visita/recarga (Rails lo descarta despues de leerlo una vez),
  // asi que no hace falta un estado "dismissed" separado para eso.
  const [showScheduledBanner, setShowScheduledBanner] = useState(
    Boolean(flash.notice),
  )
  const [previousFlashNotice, setPreviousFlashNotice] = useState(flash.notice)

  if (flash.notice !== previousFlashNotice) {
    setPreviousFlashNotice(flash.notice)
    setShowScheduledBanner(Boolean(flash.notice))
  }

  const title = t("pages.admin.benefit_configurations.index.title")

  const breadcrumbs: BreadcrumbItem[] = [
    { title, href: adminBenefitConfigurations.index().url },
  ]

  // Hay un cambio programado (todavia no vigente) cuando existe una fila
  // con effective_from en el futuro -- por la validacion de unicidad del
  // modelo solo puede haber una a la vez.
  const today = new Date().toISOString().slice(0, 10)
  const pendingBenefitConfiguration = benefit_configurations.find(
    (benefitConfiguration) => benefitConfiguration.effective_from > today,
  )

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={title} />

      <div className="mx-auto grid w-full max-w-200 gap-6 p-5">
        <div>
          <h1 className="text-xl font-bold">{title}</h1>
          <p className="text-muted-foreground text-sm">
            {t("pages.admin.benefit_configurations.index.description")}
          </p>
        </div>

        {showScheduledBanner && (
          <Alert>
            <AlertCircleIcon />
            <AlertTitle className="font-bold">
              {t(
                "pages.admin.benefit_configurations.index.current.scheduled_banner.title",
              )}
            </AlertTitle>
            <AlertDescription>
              {t(
                "pages.admin.benefit_configurations.index.current.scheduled_banner.description",
              )}
            </AlertDescription>
            <Button
              variant="ghost"
              size="icon-xs"
              className="absolute top-3 right-3"
              aria-label={t(
                "pages.admin.benefit_configurations.index.current.scheduled_banner.dismiss",
              )}
              onClick={() => setShowScheduledBanner(false)}
            >
              <XIcon />
            </Button>
          </Alert>
        )}

        <Card>
          <CardHeader>
            <CardTitle>
              {t("pages.admin.benefit_configurations.index.current.title")}
            </CardTitle>

            {!isEditing && (
              <CardAction>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setIsEditing(true)}
                >
                  <PencilIcon />
                  {t("pages.admin.benefit_configurations.index.current.edit")}
                </Button>
              </CardAction>
            )}
          </CardHeader>
          <CardContent>
            {isEditing ? (
              <EditBenefitConfigurationForm
                defaultValues={{
                  subsidy_percentage:
                    current_benefit_configuration?.subsidy_percentage ?? "",
                  max_voucher_price:
                    current_benefit_configuration?.max_voucher_price ?? "",
                  monthly_voucher_limit:
                    current_benefit_configuration?.monthly_voucher_limit ?? "",
                }}
                pendingBenefitConfiguration={pendingBenefitConfiguration}
                onCancel={() => setIsEditing(false)}
                onSuccess={() => setIsEditing(false)}
              />
            ) : current_benefit_configuration ? (
              <dl className="divide-border bg-muted divide-y rounded-lg px-4">
                <div className="flex items-center justify-between py-3">
                  <dt className="text-muted-foreground">
                    {t(
                      "pages.admin.benefit_configurations.index.current.subsidy_percentage",
                    )}
                  </dt>
                  <dd className="text-lg font-semibold">
                    {current_benefit_configuration.subsidy_percentage}%
                  </dd>
                </div>
                <div className="flex items-center justify-between py-3">
                  <dt className="text-muted-foreground">
                    {t(
                      "pages.admin.benefit_configurations.index.current.max_voucher_price",
                    )}
                  </dt>
                  <dd className="text-lg font-semibold">
                    ≤${current_benefit_configuration.max_voucher_price}
                  </dd>
                </div>
                <div className="flex items-center justify-between py-3">
                  <dt className="text-muted-foreground">
                    {t(
                      "pages.admin.benefit_configurations.index.current.monthly_voucher_limit",
                    )}
                  </dt>
                  <dd className="text-lg font-semibold">
                    {current_benefit_configuration.monthly_voucher_limit}
                  </dd>
                </div>
              </dl>
            ) : (
              <Empty>
                <EmptyHeader>
                  <EmptyTitle>
                    {t(
                      "pages.admin.benefit_configurations.index.current.empty",
                    )}
                  </EmptyTitle>
                </EmptyHeader>
              </Empty>
            )}
          </CardContent>
        </Card>
      </div>
    </AppLayout>
  )
}
