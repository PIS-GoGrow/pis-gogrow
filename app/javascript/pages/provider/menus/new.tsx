import { Head, Link } from "@inertiajs/react"
import { ChevronLeft } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import {
  AdaptableDialog,
  AdaptableDialogContent,
  AdaptableDialogDescription,
  AdaptableDialogFooter,
  AdaptableDialogHeader,
  AdaptableDialogTitle,
} from "@/components/adaptable-dialog"
import NewMenuForm from "@/components/menus/new-menu-form"
import SavedMenusTab from "@/components/menus/saved-menus-tab"
import { Button } from "@/components/ui/button"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import AppLayout from "@/layouts/app-layout"
import { formatLongDateInline } from "@/lib/dates"
import { providerMenus as menusRoutes, schedules } from "@/routes"
import type { BreadcrumbItem, ProviderMenusNew } from "@/types"

type AddedOrigin = "new" | "saved"

export default function New(props: ProviderMenusNew) {
  const { t } = useTranslation()
  const key = "pages.provider_menus.new"
  const [defaultDate] = useState(props.default_date)
  const [addedOpen, setAddedOpen] = useState(false)
  const [addedDate, setAddedDate] = useState<string | null>(null)
  const [addedOrigin, setAddedOrigin] = useState<AddedOrigin | null>(null)
  const [formKey, setFormKey] = useState(0)
  // Día al que se vuelve desde el cartel de "Plato agregado": el día donde quedó publicado.
  const [landingDate, setLandingDate] = useState<string | null>(null)

  // "Volver" lleva al día desde el que se tocó "Agregar platos".
  const backUrl = schedules.index(
    defaultDate ? { query: { date: defaultDate } } : undefined,
  ).url

  const landingUrl = schedules.index(
    landingDate ? { query: { date: landingDate } } : undefined,
  ).url

  const breadcrumbs: BreadcrumbItem[] = [
    { title: t(`${key}.title`), href: menusRoutes.new().url },
  ]

  function closeAdded() {
    setAddedOpen(false)
    if (addedOrigin === "new") setFormKey((value) => value + 1)
    setAddedOrigin(null)
  }

  function handleAddedOpenChange(open: boolean) {
    if (open) {
      setAddedOpen(true)
      return
    }

    closeAdded()
  }

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t(`${key}.title`)} />

      <div className="mx-auto w-full max-w-xl p-5">
        <div className="relative mb-6 flex h-9 items-center justify-center">
          <Button
            variant="ghost"
            size="icon"
            className="absolute left-0 -ml-2"
            asChild
          >
            <Link href={backUrl} aria-label={t(`${key}.back`)}>
              <ChevronLeft aria-hidden="true" className="size-5" />
            </Link>
          </Button>
          <h1 className="text-base font-semibold">{t(`${key}.title`)}</h1>
        </div>

        <Tabs defaultValue="new" className="gap-6">
          <TabsList className="w-full">
            <TabsTrigger value="new">{t(`${key}.tabs.new`)}</TabsTrigger>
            <TabsTrigger value="saved">{t(`${key}.tabs.saved`)}</TabsTrigger>
          </TabsList>

          <TabsContent value="new">
            <NewMenuForm
              key={formKey}
              create={{ ...props, default_date: defaultDate }}
              onCreated={(publishedDate) => {
                setAddedOrigin("new")
                setAddedDate(null)
                setLandingDate(publishedDate ?? defaultDate)
                setAddedOpen(true)
              }}
            />
          </TabsContent>

          <TabsContent value="saved">
            <SavedMenusTab
              menus={props.saved_menus}
              defaultDate={props.default_date}
              published={props.published}
              today={props.today}
              maximumPublishDate={props.maximum_publish_date}
              onPublished={(date) => {
                setAddedOrigin("saved")
                setAddedDate(date)
                setLandingDate(date)
                setAddedOpen(true)
              }}
            />
          </TabsContent>
        </Tabs>
      </div>

      <AdaptableDialog open={addedOpen} onOpenChange={handleAddedOpenChange}>
        <AdaptableDialogContent showCloseButton={false} className="p-0">
          <AdaptableDialogHeader className="items-start px-6 pt-8 text-left">
            <AdaptableDialogTitle className="text-base">
              {t(`${key}.added.title`)}
            </AdaptableDialogTitle>
            <AdaptableDialogDescription className="text-base">
              {addedDate
                ? t(`${key}.added.description_date`, {
                    date: formatLongDateInline(addedDate),
                  })
                : t(`${key}.added.description`)}
            </AdaptableDialogDescription>
          </AdaptableDialogHeader>

          <AdaptableDialogFooter className="grid grid-cols-2 gap-3 px-6 pt-6 pb-6">
            <Button variant="secondary" className="h-11" asChild>
              <Link href={landingUrl}>{t(`${key}.added.back`)}</Link>
            </Button>
            <Button type="button" className="h-11" onClick={closeAdded}>
              {t(`${key}.added.continue`)}
            </Button>
          </AdaptableDialogFooter>
        </AdaptableDialogContent>
      </AdaptableDialog>
    </AppLayout>
  )
}
