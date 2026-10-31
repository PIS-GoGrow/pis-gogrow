import { Head, Link } from "@inertiajs/react"
import { AlertCircleIcon, ArrowLeft, PencilIcon } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import DebtAlertCard from "@/components/benefit-configurations/debt-alert-card"
import EditBenefitConfigurationForm, {
  type EditBenefitConfigurationFormProps,
} from "@/components/benefit-configurations/edit-benefit-configuration-form"
import SpecialSubsidiesSection from "@/components/benefit-configurations/special-subsidies-section"
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { Button } from "@/components/ui/button"
import { Empty, EmptyHeader, EmptyTitle } from "@/components/ui/empty"
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet"
import { useIsMobile } from "@/hooks/use-mobile"
import AppLayout from "@/layouts/app-layout"
import { formatLongDateInline } from "@/lib/dates"
import { formatMoney } from "@/lib/money"
import { adminAccount, adminBenefitConfigurations } from "@/routes"
import type { BreadcrumbItem } from "@/types"
import type { AdminBenefitConfigurationsIndex } from "@/types/serializers"

export default function Index({
  pending_base_subsidies,
  base_subsidy,
  configurable_month,
  special_subsidies,
  employees,
  debt_alert_threshold,
}: AdminBenefitConfigurationsIndex) {
  const { t } = useTranslation()
  const isMobile = useIsMobile()
  const [isEditingInline, setIsEditingInline] = useState(false)
  const [isMobileSheetOpen, setIsMobileSheetOpen] = useState(false)

  const title = t("pages.admin.benefit_configurations.index.title")

  const breadcrumbs: BreadcrumbItem[] = [
    { title, href: adminBenefitConfigurations.index().url },
  ]

  const pendingBenefitSubsidy = pending_base_subsidies.find(
    (config) => config.benefit_rules[0].effective_from === configurable_month,
  )

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

  function handleStartEditing() {
    if (isMobile) {
      setIsMobileSheetOpen(true)
    } else {
      setIsEditingInline(true)
    }
  }

  const editFormProps: Pick<
    EditBenefitConfigurationFormProps,
    "defaultValues" | "pendingBenefitConfiguration" | "configurableMonth"
  > = {
    defaultValues: {
      subsidy_percentage: base_subsidy?.subsidy_percentage ?? "",
      max_voucher_price: base_subsidy?.benefit_rules[0]?.max_price ?? "",
      monthly_voucher_limit: base_subsidy?.benefit_rules[0]?.limit ?? "",
    },
    pendingBenefitConfiguration,
    configurableMonth: configurable_month,
  }

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={title} />

      <div className="mx-auto flex w-full max-w-200 flex-col gap-6 p-5 md:p-8">
        <div className="flex flex-col gap-6">
          <Button
            variant="ghost"
            size="icon"
            className="size-9 rounded-[10px] p-0"
            asChild
          >
            <Link
              href={adminAccount().url}
              aria-label={t("pages.admin.benefit_configurations.index.back")}
            >
              <ArrowLeft className="size-4" aria-hidden="true" />
            </Link>
          </Button>

          <div className="flex flex-col gap-2">
            <h1 className="text-foreground text-2xl font-bold tracking-tight">
              {title}
            </h1>
            <p className="text-base text-[#737373] dark:text-neutral-400">
              {t("pages.admin.benefit_configurations.index.description")}
            </p>
          </div>
        </div>

        <section className="flex flex-col gap-4">
          <div className="flex items-center justify-between">
            <h2 className="text-foreground text-xl font-bold">
              {t("pages.admin.benefit_configurations.index.current.title")}
            </h2>

            {!isEditingInline && (
              <Button
                variant="ghost"
                size="sm"
                className="text-foreground gap-1.5 font-semibold"
                onClick={handleStartEditing}
              >
                <PencilIcon className="size-4" />
                {t("pages.admin.benefit_configurations.index.current.edit")}
              </Button>
            )}
          </div>

          {isEditingInline ? (
            <div className="border-border bg-card rounded-lg border p-4">
              <EditBenefitConfigurationForm
                {...editFormProps}
                onCancel={() => setIsEditingInline(false)}
                onSuccess={() => setIsEditingInline(false)}
              />
            </div>
          ) : (
            <>
              {pending_base_subsidies.map((subsidy) => (
                <Alert key={subsidy.id}>
                  <AlertCircleIcon />
                  <AlertTitle className="font-bold">
                    {t(
                      "pages.admin.benefit_configurations.index.current.pending_conflict.title_alt",
                      { date: formatLongDateInline(configurable_month) },
                    )}
                  </AlertTitle>
                  <AlertDescription>
                    {t(
                      "pages.admin.benefit_configurations.index.current.pending_conflict.description",
                      {
                        subsidy_percentage: subsidy.subsidy_percentage,
                        max_voucher_price: formatMoney(
                          subsidy.benefit_rules[0]?.max_price ?? 0,
                        ),
                        monthly_voucher_limit: subsidy.benefit_rules[0]?.limit,
                      },
                    )}
                  </AlertDescription>
                </Alert>
              ))}

              {base_subsidy ? (
                <div className="flex flex-col gap-3 rounded-lg border border-[#E5E5E5] bg-[#F5F5F5] p-4 dark:border-neutral-800 dark:bg-neutral-900">
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-medium text-[#737373] dark:text-neutral-400">
                      {t(
                        "pages.admin.benefit_configurations.index.current.subsidy_percentage",
                      )}
                    </span>
                    <span className="text-foreground text-base font-medium">
                      {base_subsidy.subsidy_percentage}%
                    </span>
                  </div>

                  <div className="border-t border-[#E5E5E5] dark:border-neutral-800" />

                  <div className="flex items-center justify-between">
                    <span className="text-sm font-medium text-[#737373] dark:text-neutral-400">
                      {t(
                        "pages.admin.benefit_configurations.index.current.max_voucher_price",
                      )}
                    </span>
                    <span className="text-foreground text-base font-medium">
                      ≤
                      {formatMoney(
                        base_subsidy?.benefit_rules[0]?.max_price ?? 0,
                      )}
                    </span>
                  </div>

                  <div className="border-t border-[#E5E5E5] dark:border-neutral-800" />

                  <div className="flex items-center justify-between">
                    <span className="text-sm font-medium text-[#737373] dark:text-neutral-400">
                      {t(
                        "pages.admin.benefit_configurations.index.current.monthly_voucher_limit",
                      )}
                    </span>
                    <span className="text-foreground text-base font-medium">
                      {base_subsidy?.benefit_rules[0]?.limit}
                    </span>
                  </div>
                </div>
              ) : (
                <Empty className="border-0 bg-transparent">
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
        </section>

        {/* Mobile Bottom Sheet Editor */}
        <Sheet open={isMobileSheetOpen} onOpenChange={setIsMobileSheetOpen}>
          <SheetContent
            side="bottom"
            showCloseButton={false}
            className="max-h-[90dvh] overflow-y-auto rounded-t-2xl p-6"
          >
            <div className="bg-muted mx-auto mb-4 h-1.5 w-12 rounded-full" />
            <SheetHeader className="p-0 text-left">
              <SheetTitle className="text-foreground text-xl font-bold">
                {t("pages.admin.benefit_configurations.index.current.title")}
              </SheetTitle>
            </SheetHeader>
            <div className="mt-4">
              <EditBenefitConfigurationForm
                {...editFormProps}
                onCancel={() => setIsMobileSheetOpen(false)}
                onSuccess={() => setIsMobileSheetOpen(false)}
              />
            </div>
          </SheetContent>
        </Sheet>

        <SpecialSubsidiesSection
          specialSubsidies={special_subsidies}
          employees={employees}
        />

        <DebtAlertCard threshold={debt_alert_threshold} />
      </div>
    </AppLayout>
  )
}
