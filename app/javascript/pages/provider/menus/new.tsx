import { Head, Link } from "@inertiajs/react"
import { ChevronLeft } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import NewMenuForm from "@/components/menus/new-menu-form"
import { Button } from "@/components/ui/button"
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetFooter,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import AppLayout from "@/layouts/app-layout"
import { providerMenus as menusRoutes, schedules } from "@/routes"
import type { BreadcrumbItem, ProviderMenusNew } from "@/types"

export default function New(props: ProviderMenusNew) {
  const { t } = useTranslation()
  const key = "pages.provider_menus.new"
  const [addedOpen, setAddedOpen] = useState(false)
  const [formKey, setFormKey] = useState(0)

  const breadcrumbs: BreadcrumbItem[] = [
    { title: t(`${key}.title`), href: menusRoutes.new().url },
  ]

  function keepAdding() {
    setAddedOpen(false)
    setFormKey((value) => value + 1)
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
            <Link href={schedules.index().url} aria-label={t(`${key}.back`)}>
              <ChevronLeft aria-hidden="true" className="size-5" />
            </Link>
          </Button>
          <h1 className="text-base font-semibold">{t(`${key}.title`)}</h1>
        </div>

        <Tabs value="new" className="gap-6">
          <TabsList className="w-full">
            <TabsTrigger value="new">{t(`${key}.tabs.new`)}</TabsTrigger>
            <TabsTrigger value="saved">{t(`${key}.tabs.saved`)}</TabsTrigger>
          </TabsList>

          <TabsContent value="new">
            <NewMenuForm
              key={formKey}
              create={props}
              onCreated={() => setAddedOpen(true)}
            />
          </TabsContent>
        </Tabs>
      </div>

      <Sheet open={addedOpen} onOpenChange={setAddedOpen}>
        <SheetContent
          side="bottom"
          showCloseButton={false}
          className="mx-auto gap-0 rounded-t-3xl pb-[env(safe-area-inset-bottom)] md:max-w-xl"
        >
          <div className="bg-muted-foreground/30 mx-auto mt-3 h-1 w-10 rounded-full" />

          <SheetHeader className="items-start px-6 pt-8 text-left">
            <SheetTitle className="text-base">
              {t(`${key}.added.title`)}
            </SheetTitle>
            <SheetDescription className="text-base">
              {t(`${key}.added.description`)}
            </SheetDescription>
          </SheetHeader>

          <SheetFooter className="grid grid-cols-2 gap-3 px-6 pt-6 pb-6">
            <Button variant="secondary" className="h-11" asChild>
              <Link href={schedules.index().url}>{t(`${key}.added.back`)}</Link>
            </Button>
            <Button type="button" className="h-11" onClick={keepAdding}>
              {t(`${key}.added.continue`)}
            </Button>
          </SheetFooter>
        </SheetContent>
      </Sheet>
    </AppLayout>
  )
}
