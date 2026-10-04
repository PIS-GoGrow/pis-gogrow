import { Form, Head, Link, router } from "@inertiajs/react"
import { ArrowLeft, Clock3 } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import PageContainer from "@/components/page-container"
import { Button } from "@/components/ui/button"
import { Field, FieldError, FieldLabel } from "@/components/ui/field"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetFooter,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet"
import AppLayout from "@/layouts/app-layout"
import {
  providerAccount,
  providerOperationalSettings,
  providerOrderDeadline,
} from "@/routes"
import type { BreadcrumbItem } from "@/types"
import type { ProviderOperationalSettingsShow } from "@/types/serializers/ProviderOperationalSettingsShow"

const quarterHourOptions = Array.from({ length: 96 }, (_, index) => {
  const hours = String(Math.floor(index / 4)).padStart(2, "0")
  const minutes = String((index % 4) * 15).padStart(2, "0")
  return `${hours}:${minutes}`
})

export default function OperationalSettings({
  provider,
  order_deadline_passed_today,
}: ProviderOperationalSettingsShow) {
  const { t } = useTranslation()
  const [sheetOpen, setSheetOpen] = useState(false)
  const [sheetStage, setSheetStage] = useState<"form" | "saved">("form")
  const [newTime, setNewTime] = useState("10:00")
  const [editError, setEditError] = useState<string | undefined>()
  const page = "pages.provider_operational_settings.show"
  const options =
    provider.order_deadline &&
    !quarterHourOptions.includes(provider.order_deadline)
      ? [...quarterHourOptions, provider.order_deadline].sort()
      : quarterHourOptions

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.provider_accounts.show.title"),
      href: providerAccount().url,
    },
    { title: t(`${page}.title`), href: providerOperationalSettings.show().url },
  ]

  const closeSheet = () => {
    setSheetOpen(false)
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
        <section className="rounded-xl border p-4">
          <div className="mb-4 flex items-start gap-3">
            <Clock3 className="mt-0.5 size-5 shrink-0" aria-hidden="true" />
            <div>
              <h3 className="text-base font-semibold">
                {t(`${page}.closing_time`)}
              </h3>
              <p className="text-muted-foreground text-sm">
                {t(`${page}.closing_time_description`)}
              </p>
            </div>
          </div>

          {provider.order_deadline ? (
            <div>
              <Select
                value={provider.order_deadline}
                onValueChange={(value) => {
                  setEditError(undefined)
                  router.patch(
                    providerOrderDeadline().url,
                    { order_deadline: value },
                    {
                      preserveScroll: true,
                      onError: (errors) =>
                        setEditError(errors.order_deadline?.[0]),
                      onSuccess: () => {
                        setNewTime(value)
                        setSheetStage("saved")
                        setSheetOpen(true)
                      },
                    },
                  )
                }}
              >
                <SelectTrigger
                  className="w-full"
                  aria-label={t(`${page}.closing_time`)}
                  aria-invalid={!!editError}
                >
                  <SelectValue />
                </SelectTrigger>
                <SelectContent className="max-h-48">
                  {options.map((time) => (
                    <SelectItem key={time} value={time}>
                      {time}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              {editError && <FieldError>{editError}</FieldError>}
            </div>
          ) : (
            <Button
              type="button"
              className="h-11 w-full"
              onClick={() => {
                setSheetStage("form")
                setNewTime("10:00")
                setSheetOpen(true)
              }}
            >
              {t(`${page}.add_closing_time`)}
            </Button>
          )}
        </section>
      </PageContainer>

      <Sheet open={sheetOpen} onOpenChange={(open) => !open && closeSheet()}>
        <SheetContent
          side="bottom"
          showCloseButton={false}
          className="mx-auto gap-0 rounded-t-3xl pb-[env(safe-area-inset-bottom)] md:max-w-xl"
        >
          <div className="bg-muted-foreground/30 mx-auto mt-3 h-1 w-10 rounded-full" />
          {sheetStage === "form" ? (
            <Form
              method="patch"
              action={providerOrderDeadline().url}
              options={{ preserveScroll: true }}
              onSuccess={() => setSheetStage("saved")}
            >
              {({ errors, processing }) => (
                <>
                  <SheetHeader className="px-6 pt-6 pb-4">
                    <SheetTitle className="text-xl">
                      {t(`${page}.add_closing_time_title`)}
                    </SheetTitle>
                    <SheetDescription className="sr-only">
                      {t(`${page}.closing_time_description`)}
                    </SheetDescription>
                  </SheetHeader>
                  <div className="px-6 pb-6">
                    <Field>
                      <FieldLabel htmlFor="order_deadline">
                        {t(`${page}.closing_time`)}
                      </FieldLabel>
                      <Select
                        name="order_deadline"
                        value={newTime}
                        onValueChange={setNewTime}
                      >
                        <SelectTrigger
                          id="order_deadline"
                          className="w-full"
                          aria-invalid={!!errors.order_deadline}
                        >
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent className="max-h-48">
                          {quarterHourOptions.map((time) => (
                            <SelectItem key={time} value={time}>
                              {time}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                      <FieldError
                        errors={errors.order_deadline?.map((message) => ({
                          message,
                        }))}
                      />
                    </Field>
                  </div>
                  <SheetFooter className="flex-row gap-3 px-6 pb-6">
                    <Button
                      type="button"
                      variant="secondary"
                      className="h-11 flex-1"
                      onClick={closeSheet}
                    >
                      {t("common.cancel")}
                    </Button>
                    <Button
                      type="submit"
                      className="h-11 flex-1"
                      disabled={processing}
                    >
                      {t(`${page}.save_changes`)}
                    </Button>
                  </SheetFooter>
                </>
              )}
            </Form>
          ) : (
            <>
              <SheetHeader className="items-start px-6 pt-8 text-left">
                <SheetTitle className="text-base">
                  {t(`${page}.saved_title`)}
                </SheetTitle>
                <SheetDescription>
                  {t(
                    `${page}.${order_deadline_passed_today ? "saved_description_closed_today" : "saved_description"}`,
                    { time: newTime },
                  )}
                </SheetDescription>
              </SheetHeader>
              <SheetFooter className="px-6 pt-6 pb-6">
                <Button
                  type="button"
                  className="h-11 w-full"
                  onClick={closeSheet}
                >
                  {t(`${page}.done`)}
                </Button>
              </SheetFooter>
            </>
          )}
        </SheetContent>
      </Sheet>
    </AppLayout>
  )
}
