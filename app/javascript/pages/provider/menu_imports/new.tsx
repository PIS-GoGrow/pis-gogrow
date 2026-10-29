import { Head, Link, router, useForm } from "@inertiajs/react"
import { ChevronLeft, TriangleAlert } from "lucide-react"
import { useTranslation } from "react-i18next"

import ImportedDialog from "@/components/menus/import/imported-dialog"
import Review from "@/components/menus/import/review"
import UploadStep from "@/components/menus/import/upload-step"
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { Button } from "@/components/ui/button"
import AppLayout from "@/layouts/app-layout"
import { providerMenuImports, schedules } from "@/routes"
import type { BreadcrumbItem, ProviderMenuImportsNew } from "@/types"

const KEY = "pages.provider_menu_imports.new"

export default function New({
  template_path,
  formats,
  max_size_mb,
  today,
  maximum_publish_date,
  saved_menus,
  preview,
  imported,
}: ProviderMenuImportsNew) {
  const { t } = useTranslation()
  const upload = useForm<{ file: File | null }>({ file: null })

  const breadcrumbs: BreadcrumbItem[] = [
    { title: t(`${KEY}.title`), href: providerMenuImports.new().url },
  ]

  // Empezar de nuevo es volver a entrar a la pantalla: así se descarta la
  // planilla anterior sin dejar nada a medias.
  function restart() {
    router.get(providerMenuImports.new().url)
  }

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t(`${KEY}.title`)} />

      {/* pb-24 en celular: abajo está la barra de navegación. */}
      <div className="mx-auto flex w-full max-w-xl flex-col gap-6 p-5 pb-24 md:pb-5">
        {preview && !preview.error ? (
          // La clave reinicia lo que se venía revisando cuando llega otra
          // planilla: lo editado pertenece al archivo que se subió.
          <Review
            key={preview.id}
            preview={preview}
            savedMenus={saved_menus}
            today={today}
            maximumPublishDate={maximum_publish_date}
            onRestart={restart}
          />
        ) : (
          <>
            <div className="relative flex h-9 items-center justify-center">
              <Button
                variant="ghost"
                size="icon"
                className="absolute left-0 -ml-2"
                aria-label={t(`${KEY}.back`)}
                asChild
              >
                <Link href={schedules.index().url}>
                  <ChevronLeft aria-hidden="true" className="size-5" />
                </Link>
              </Button>
              <h1 className="text-lg font-semibold">{t(`${KEY}.title`)}</h1>
            </div>

            <p className="text-muted-foreground text-sm">{t(`${KEY}.intro`)}</p>

            <UploadStep
              templatePath={template_path}
              formats={formats}
              maxSizeMb={max_size_mb}
              file={upload.data.file}
              processing={upload.processing}
              onChoose={(file) => upload.setData("file", file)}
              onUpload={() =>
                upload.post(providerMenuImports.create().url, {
                  preserveState: true,
                  preserveScroll: true,
                })
              }
            />

            {preview?.error && (
              <Alert variant="destructive">
                <TriangleAlert aria-hidden="true" />
                <AlertTitle>{t(`${KEY}.file_error`)}</AlertTitle>
                <AlertDescription>{preview.error}</AlertDescription>
              </Alert>
            )}
          </>
        )}
      </div>

      <ImportedDialog open={imported !== null} onAgain={restart} />
    </AppLayout>
  )
}
