import { Head } from "@inertiajs/react"
import { PencilIcon, PlusIcon } from "lucide-react"
import { useTranslation } from "react-i18next"

import EditBenefitConfigurationDialog from "@/components/benefit-configurations/edit-benefit-configuration-dialog"
import { Button } from "@/components/ui/button"
import {
  Card,
  CardAction,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { DialogTrigger } from "@/components/ui/dialog"
import { Empty, EmptyHeader, EmptyTitle } from "@/components/ui/empty"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import AppLayout from "@/layouts/app-layout"
import { adminBenefitConfigurations } from "@/routes"
import type { BreadcrumbItem } from "@/types"
import type { AdminBenefitConfigurationsIndex } from "@/types/serializers"

// La fecha de fin de vigencia no se guarda: se calcula como el día anterior a
// que arranque la siguiente configuración (o "sin fin todavía" si es la más
// reciente). `benefit_configurations` ya viene ordenada de más nueva a más
// vieja (ver BenefitConfiguration.ordered), así que la siguiente en el tiempo
// es la de índice anterior en el array.
function effectiveUntil(
  index: number,
  configurations: { effective_from: string }[],
) {
  if (index === 0) return null

  const nextEffectiveFrom = configurations[index - 1].effective_from
  const dayBefore = new Date(`${nextEffectiveFrom}T00:00:00Z`)
  dayBefore.setUTCDate(dayBefore.getUTCDate() - 1)
  return dayBefore.toISOString().slice(0, 10)
}

export default function Index({
  current_benefit_configuration,
  benefit_configurations,
}: AdminBenefitConfigurationsIndex) {
  const { t } = useTranslation()

  const title = t("pages.admin.benefit_configurations.index.title")

  const breadcrumbs: BreadcrumbItem[] = [
    { title, href: adminBenefitConfigurations.index().url },
  ]

  const currentIndex = benefit_configurations.findIndex(
    (configuration) => configuration.id === current_benefit_configuration?.id,
  )
  const currentUntil =
    currentIndex === -1
      ? null
      : effectiveUntil(currentIndex, benefit_configurations)

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

            <CardAction>
              <EditBenefitConfigurationDialog
                currentBenefitConfiguration={current_benefit_configuration}
              >
                <DialogTrigger asChild>
                  <Button variant="outline" size="sm">
                    {current_benefit_configuration ? (
                      <>
                        <PencilIcon />
                        {t(
                          "pages.admin.benefit_configurations.index.current.edit",
                        )}
                      </>
                    ) : (
                      <>
                        <PlusIcon />
                        {t(
                          "pages.admin.benefit_configurations.index.current.configure",
                        )}
                      </>
                    )}
                  </Button>
                </DialogTrigger>
              </EditBenefitConfigurationDialog>
            </CardAction>
          </CardHeader>
          <CardContent>
            {current_benefit_configuration ? (
              <dl className="grid grid-cols-2 gap-4 sm:grid-cols-3">
                <div>
                  <dt className="text-muted-foreground text-sm">
                    {t(
                      "pages.admin.benefit_configurations.index.current.subsidy_percentage",
                    )}
                  </dt>
                  <dd className="text-lg font-semibold">
                    {current_benefit_configuration.subsidy_percentage}%
                  </dd>
                </div>
                <div>
                  <dt className="text-muted-foreground text-sm">
                    {t(
                      "pages.admin.benefit_configurations.index.current.max_voucher_price",
                    )}
                  </dt>
                  <dd className="text-lg font-semibold">
                    ${current_benefit_configuration.max_voucher_price}
                  </dd>
                </div>
                <div>
                  <dt className="text-muted-foreground text-sm">
                    {t(
                      "pages.admin.benefit_configurations.index.current.monthly_voucher_limit",
                    )}
                  </dt>
                  <dd className="text-lg font-semibold">
                    {current_benefit_configuration.monthly_voucher_limit}
                  </dd>
                </div>
                <div>
                  <dt className="text-muted-foreground text-sm">
                    {t(
                      "pages.admin.benefit_configurations.index.current.effective_from",
                    )}
                  </dt>
                  <dd className="text-lg font-semibold">
                    {current_benefit_configuration.effective_from}
                  </dd>
                </div>
                <div>
                  <dt className="text-muted-foreground text-sm">
                    {t(
                      "pages.admin.benefit_configurations.index.current.effective_until",
                    )}
                  </dt>
                  <dd className="text-lg font-semibold">
                    {currentUntil ??
                      t(
                        "pages.admin.benefit_configurations.index.history.current",
                      )}
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

        <Card>
          <CardHeader>
            <CardTitle>
              {t("pages.admin.benefit_configurations.index.history.title")}
            </CardTitle>
          </CardHeader>
          <CardContent>
            {benefit_configurations.length === 0 ? (
              <Empty>
                <EmptyHeader>
                  <EmptyTitle>
                    {t(
                      "pages.admin.benefit_configurations.index.history.empty",
                    )}
                  </EmptyTitle>
                </EmptyHeader>
              </Empty>
            ) : (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>
                      {t(
                        "pages.admin.benefit_configurations.index.history.subsidy_percentage",
                      )}
                    </TableHead>
                    <TableHead>
                      {t(
                        "pages.admin.benefit_configurations.index.history.max_voucher_price",
                      )}
                    </TableHead>
                    <TableHead>
                      {t(
                        "pages.admin.benefit_configurations.index.history.monthly_voucher_limit",
                      )}
                    </TableHead>
                    <TableHead>
                      {t(
                        "pages.admin.benefit_configurations.index.history.effective_from",
                      )}
                    </TableHead>
                    <TableHead>
                      {t(
                        "pages.admin.benefit_configurations.index.history.effective_until",
                      )}
                    </TableHead>
                    <TableHead>
                      {t(
                        "pages.admin.benefit_configurations.index.history.created_by",
                      )}
                    </TableHead>
                    <TableHead>
                      {t(
                        "pages.admin.benefit_configurations.index.history.created_at",
                      )}
                    </TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {benefit_configurations.map((configuration, index) => {
                    const until = effectiveUntil(index, benefit_configurations)
                    const isCurrent =
                      current_benefit_configuration?.id === configuration.id

                    return (
                      <TableRow key={configuration.id}>
                        <TableCell>
                          {configuration.subsidy_percentage}%
                        </TableCell>
                        <TableCell>
                          ${configuration.max_voucher_price}
                        </TableCell>
                        <TableCell>
                          {configuration.monthly_voucher_limit}
                        </TableCell>
                        <TableCell>{configuration.effective_from}</TableCell>
                        <TableCell>
                          {until ??
                            (isCurrent
                              ? t(
                                  "pages.admin.benefit_configurations.index.history.current",
                                )
                              : "—")}
                        </TableCell>
                        <TableCell>{configuration.created_by_name}</TableCell>
                        <TableCell>
                          {new Date(configuration.created_at).toLocaleString()}
                        </TableCell>
                      </TableRow>
                    )
                  })}
                </TableBody>
              </Table>
            )}
          </CardContent>
        </Card>
      </div>
    </AppLayout>
  )
}
