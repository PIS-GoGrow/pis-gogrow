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
  pending_base_subsidies,
  base_subsidy,
  configurable_month,
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
  console.log(pending_base_subsidies)
  const pendingBenefitSubsidy = pending_base_subsidies.find((config) => config.benefit_rules[0].effective_from === configurable_month)

  const pendingBenefitConfiguration:
    | {
        subsidy_percentage: number | ""
        max_voucher_price: number | ""
        monthly_voucher_limit: number | ""
      }
    | undefined = pendingBenefitSubsidy
    ? {
        subsidy_percentage: pendingBenefitSubsidy?.subsidy_percentage ?? "",
        max_voucher_price:
          pendingBenefitSubsidy?.benefit_rules[0]?.max_price ?? "",
        monthly_voucher_limit:
          pendingBenefitSubsidy?.benefit_rules[0]?.limit ?? "",
      }
    : undefined

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

        <Card>
          <CardHeader>
            <CardTitle>
              {t("pages.admin.benefit_configurations.index.current.title")}
            </CardTitle>

            {!isEditing && (
              <CardAction>
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => setIsEditing(true)}
                >
                  <PencilIcon />
                  {t("pages.admin.benefit_configurations.index.current.edit")}
                </Button>
              </CardAction>
            )}
          </CardHeader>
          <CardContent className="grid gap-2">
            {isEditing ? (
              <EditBenefitConfigurationForm
                defaultValues={{
                  subsidy_percentage: base_subsidy?.subsidy_percentage ?? "",
                  max_voucher_price:
                    base_subsidy?.benefit_rules[0]?.max_price ?? "",
                  monthly_voucher_limit:
                    base_subsidy?.benefit_rules[0]?.limit ?? "",
                }}
                pendingBenefitConfiguration={pendingBenefitConfiguration}
                configurableMonth={configurable_month}
                onCancel={() => setIsEditing(false)}
                onSuccess={() => setIsEditing(false)}
              />
            ) : (
              <>
              {pending_base_subsidies.map((subsidy) =>(
                <Alert>
                  <AlertCircleIcon />
                  <AlertTitle className="font-bold">
                    {t(
                      "pages.admin.benefit_configurations.index.current.pending_conflict.title_alt", { date: configurable_month },
                    )}
                  </AlertTitle>
                  <AlertDescription>
                    {t(
                      "pages.admin.benefit_configurations.index.current.pending_conflict.description",
                      {
                        subsidy_percentage:
                          subsidy.subsidy_percentage,
                        max_voucher_price:
                          subsidy.benefit_rules[0]?.max_price,
                        monthly_voucher_limit:
                          subsidy.benefit_rules[0]?.limit,
                      },
                    )}
                  </AlertDescription>
                </Alert>
              ))}
              {base_subsidy ? (
              <dl className="divide-border bg-muted divide-y rounded-lg px-4">
                <div className="flex items-center justify-between py-3">
                  <dt className="text-muted-foreground">
                    {t(
                      "pages.admin.benefit_configurations.index.current.subsidy_percentage",
                    )}
                  </dt>
                  <dd className="text-lg font-semibold">
                    {base_subsidy.subsidy_percentage}%
                  </dd>
                </div>
                <div className="flex items-center justify-between py-3">
                  <dt className="text-muted-foreground">
                    {t(
                      "pages.admin.benefit_configurations.index.current.max_voucher_price",
                    )}
                  </dt>
                  <dd className="text-lg font-semibold">
                    ≤${base_subsidy?.benefit_rules[0]?.max_price}
                  </dd>
                </div>
                <div className="flex items-center justify-between py-3">
                  <dt className="text-muted-foreground">
                    {t(
                      "pages.admin.benefit_configurations.index.current.monthly_voucher_limit",
                    )}
                  </dt>
                  <dd className="text-lg font-semibold">
                    {base_subsidy?.benefit_rules[0]?.limit}
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
            </>
            )}
          </CardContent>
        </Card>
      </div>
    </AppLayout>
  )
}
