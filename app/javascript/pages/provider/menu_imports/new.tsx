import { Head, Link, useForm } from "@inertiajs/react"
import { ChevronLeft, Download, FileSpreadsheet, Upload } from "lucide-react"
import { useTranslation } from "react-i18next"

import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { Label } from "@/components/ui/label"
import AppLayout from "@/layouts/app-layout"
import { providerMenuImports, schedules } from "@/routes"
import type { BreadcrumbItem, ProviderMenuImportsNew } from "@/types"

export default function New({
  template_path,
  max_rows,
  max_size_mb,
  preview,
}: ProviderMenuImportsNew) {
  const { t } = useTranslation()
  const key = "pages.provider_menu_imports.new"
  const form = useForm<{ file: File | null }>({ file: null })

  // Si el proveedor elige otra planilla, la vista previa anterior ya no habla
  // de ese archivo: se esconde hasta que la vuelva a pedir.
  const shown =
    preview?.filename === (form.data.file?.name ?? null) ? preview : null
  const entries = shown?.entries ?? []
  const toCreate = entries.filter((entry) => entry.action === "create").length
  const toUpdate = entries.filter((entry) => entry.action === "update").length

  const breadcrumbs: BreadcrumbItem[] = [
    { title: t(`${key}.title`), href: providerMenuImports.new().url },
  ]

  // La planilla se manda de nuevo al confirmar: no queda guardada en el
  // servidor entre la vista previa y la importación.
  function send(url: string) {
    form.post(url, { preserveState: true, preserveScroll: true })
  }

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t(`${key}.title`)} />

      {/* pb-24 en celular: abajo está la barra de navegación. */}
      <div className="mx-auto flex w-full max-w-xl flex-col gap-6 p-5 pb-24 md:pb-5">
        <div className="relative flex h-9 items-center justify-center">
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
          <h1 className="text-lg font-semibold">{t(`${key}.title`)}</h1>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>{t(`${key}.steps.title`)}</CardTitle>
            <CardDescription>
              {t(`${key}.limits`, { rows: max_rows, size: max_size_mb })}
            </CardDescription>
          </CardHeader>
          <CardContent className="flex flex-col gap-4">
            <ol className="text-muted-foreground list-decimal space-y-1 pl-5 text-sm">
              <li>{t(`${key}.steps.download`)}</li>
              <li>{t(`${key}.steps.fill`)}</li>
              <li>{t(`${key}.steps.upload`)}</li>
            </ol>

            <Button variant="secondary" className="h-11" asChild>
              <a href={template_path} download>
                <Download aria-hidden="true" />
                {t(`${key}.template`)}
              </a>
            </Button>
          </CardContent>
        </Card>

        {/*
          El input va escondido y se abre desde la etiqueta: el control nativo
          muestra su texto en el idioma del navegador ("Choose File"), que no
          es el de la aplicación.
        */}
        <div className="flex flex-col gap-2">
          <Label htmlFor="file">{t(`${key}.file_label`)}</Label>
          <div className="flex items-center gap-3">
            <Button variant="outline" className="h-11 shrink-0" asChild>
              <label htmlFor="file">
                <FileSpreadsheet aria-hidden="true" />
                {t(`${key}.choose`)}
              </label>
            </Button>
            <span className="text-muted-foreground truncate text-sm">
              {form.data.file?.name ?? t(`${key}.no_file`)}
            </span>
          </div>
          <input
            id="file"
            type="file"
            accept=".xlsx,.csv,.ods"
            className="sr-only"
            onChange={(event) =>
              form.setData("file", event.target.files?.[0] ?? null)
            }
          />
        </div>

        {shown?.error ? (
          <Alert variant="destructive">
            <FileSpreadsheet aria-hidden="true" />
            <AlertTitle>{t(`${key}.file_error`)}</AlertTitle>
            <AlertDescription>{shown.error}</AlertDescription>
          </Alert>
        ) : null}

        {entries.length > 0 ? (
          <Card>
            <CardHeader>
              <CardTitle>{t(`${key}.preview.title`)}</CardTitle>
              <CardDescription>
                {t(`${key}.preview.counts`, {
                  create: toCreate,
                  update: toUpdate,
                })}
              </CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col gap-3">
              {entries.map((entry) => (
                <div
                  key={entry.number}
                  className="border-border flex flex-col gap-1 border-b pb-3 last:border-0 last:pb-0"
                >
                  <div className="flex items-start justify-between gap-2">
                    <span className="font-medium">
                      {entry.name || t(`${key}.preview.unnamed`)}
                    </span>
                    <Badge
                      variant={
                        entry.action === "create" ? "default" : "secondary"
                      }
                    >
                      {t(`${key}.preview.${entry.action}`)}
                    </Badge>
                  </div>
                  <span className="text-muted-foreground text-xs">
                    {t(`${key}.preview.row`, { number: entry.number })}
                  </span>
                  {entry.errors.length > 0 ? (
                    <ul className="text-destructive list-disc pl-5 text-sm">
                      {entry.errors.map((error) => (
                        <li key={error}>{error}</li>
                      ))}
                    </ul>
                  ) : null}
                </div>
              ))}
            </CardContent>
          </Card>
        ) : null}

        {shown && !shown.can_import && !shown.error ? (
          <Alert variant="destructive">
            <FileSpreadsheet aria-hidden="true" />
            <AlertTitle>{t(`${key}.preview.errors_title`)}</AlertTitle>
            <AlertDescription>
              {t(`${key}.preview.errors_description`)}
            </AlertDescription>
          </Alert>
        ) : null}

        {/*
          Con la vista previa en orden, lo que sigue es confirmar: ese pasa a
          ser el botón principal y revisar de nuevo queda en segundo plano.
        */}
        <div className="flex flex-col gap-3">
          {shown?.can_import ? (
            <Button
              className="h-11"
              disabled={!form.data.file || form.processing}
              onClick={() => send(providerMenuImports.confirm().url)}
            >
              {t(`${key}.preview.confirm`)}
            </Button>
          ) : null}

          <Button
            variant={shown?.can_import ? "outline" : "default"}
            className="h-11"
            disabled={!form.data.file || form.processing}
            onClick={() => send(providerMenuImports.create().url)}
          >
            <Upload aria-hidden="true" />
            {t(`${key}.preview_button`)}
          </Button>
        </div>
      </div>
    </AppLayout>
  )
}
