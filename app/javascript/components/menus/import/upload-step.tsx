import { Download, FileText, X } from "lucide-react"
import { useRef } from "react"
import { useTranslation } from "react-i18next"

import { Button } from "@/components/ui/button"

// "2.4 MB", como lo muestra el sistema operativo al elegir el archivo.
function formatSize(bytes: number) {
  return `${(bytes / 1024 / 1024).toFixed(1)} MB`
}

function Step({
  number,
  title,
  description,
  children,
}: {
  number: number
  title: string
  description: string
  children: React.ReactNode
}) {
  return (
    <div className="rounded-xl border p-4">
      <div className="flex items-center gap-3">
        <span
          aria-hidden="true"
          className="bg-foreground text-background flex size-6 shrink-0 items-center justify-center rounded-full text-xs font-semibold"
        >
          {number}
        </span>
        <span className="font-medium">{title}</span>
      </div>

      <p className="text-muted-foreground mt-2 text-sm">{description}</p>

      <div className="mt-4">{children}</div>
    </div>
  )
}

interface UploadStepProps {
  templatePath: string
  formats: string[]
  maxSizeMb: number
  file: File | null
  processing: boolean
  onChoose: (file: File | null) => void
  onUpload: () => void
}

export default function UploadStep({
  templatePath,
  formats,
  maxSizeMb,
  file,
  processing,
  onChoose,
  onUpload,
}: UploadStepProps) {
  const { t } = useTranslation()
  const key = "pages.provider_menu_imports.new"
  const input = useRef<HTMLInputElement>(null)

  return (
    <div className="flex flex-col gap-4">
      <Step
        number={1}
        title={t(`${key}.download.title`)}
        description={t(`${key}.download.description`)}
      >
        <Button variant="secondary" className="h-11 w-full" asChild>
          <a href={templatePath} download>
            <Download aria-hidden="true" />
            {t(`${key}.download.action`)}
          </a>
        </Button>
      </Step>

      <Step
        number={2}
        title={t(`${key}.upload.title`)}
        description={t(`${key}.upload.description`, {
          formats: formats
            .map((format) => format.replace(".", "").toUpperCase())
            .join(", "),
          size: maxSizeMb,
        })}
      >
        {/*
          El input va escondido y se abre desde el botón: el control nativo
          muestra su texto en el idioma del navegador ("Choose File"), que no es
          necesariamente el de la aplicación.
        */}
        <input
          ref={input}
          id="file"
          type="file"
          accept={formats.join(",")}
          className="sr-only"
          onChange={(event) => onChoose(event.target.files?.[0] ?? null)}
        />

        {file ? (
          <div className="flex items-center gap-3 rounded-lg border p-3">
            <FileText
              aria-hidden="true"
              className="text-muted-foreground size-5 shrink-0"
            />
            <div className="min-w-0 flex-1">
              <p className="truncate text-sm font-medium">{file.name}</p>
              <p className="text-muted-foreground text-xs">
                {formatSize(file.size)}
              </p>
            </div>
            <Button
              variant="ghost"
              size="icon-sm"
              aria-label={t(`${key}.upload.remove`)}
              onClick={() => {
                if (input.current) input.current.value = ""
                onChoose(null)
              }}
            >
              <X aria-hidden="true" />
            </Button>
          </div>
        ) : (
          <div className="flex items-center gap-3 rounded-lg border p-2 pr-3">
            <Button
              variant="outline"
              className="shrink-0"
              onClick={() => input.current?.click()}
            >
              {t(`${key}.upload.choose`)}
            </Button>
            <span className="text-muted-foreground truncate text-sm">
              {t(`${key}.upload.empty`)}
            </span>
          </div>
        )}

        <Button
          className="mt-4 h-11 w-full"
          disabled={!file || processing}
          onClick={onUpload}
        >
          {t(`${key}.upload.action`)}
        </Button>
      </Step>
    </div>
  )
}
