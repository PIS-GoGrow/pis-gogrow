import { router, useForm } from "@inertiajs/react"
import { Download, FileText, Trash2 } from "lucide-react"
import { useRef, useState } from "react"
import { useTranslation } from "react-i18next"

import { Button, buttonVariants } from "@/components/ui/button"
import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import {
  Field,
  FieldDescription,
  FieldError,
  FieldLabel,
} from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { Progress } from "@/components/ui/progress"
import { Spinner } from "@/components/ui/spinner"
import { useFormatters } from "@/hooks/use-formatters"
import { cn } from "@/lib/utils"
import { providerInvoices } from "@/routes"
import type { ProviderCollectionAccount, ProviderInvoice } from "@/types"

interface InvoiceSectionProps {
  account: ProviderCollectionAccount
  settled?: boolean
}

// La fecha local del navegador: en Montevideo coincide con Date.current.
function today() {
  const now = new Date()
  const month = String(now.getMonth() + 1).padStart(2, "0")
  const day = String(now.getDate()).padStart(2, "0")

  return `${now.getFullYear()}-${month}-${day}`
}

function InvoiceFile({ invoice }: { invoice: ProviderInvoice }) {
  const { t } = useTranslation()

  return (
    <div className="bg-background flex items-center gap-3 rounded-lg border p-3">
      <span className="bg-muted flex size-10 shrink-0 items-center justify-center rounded-md">
        <FileText className="size-5" aria-hidden="true" />
      </span>

      <a
        href={providerInvoices.file(invoice.id).url}
        target="_blank"
        rel="noreferrer"
        aria-label={t("pages.provider_collections.invoice.preview", {
          name: invoice.file_name,
        })}
        className="grid min-w-0 flex-1 hover:underline"
      >
        <span className="truncate text-sm font-medium">
          {invoice.file_name}
        </span>
        <span className="text-muted-foreground text-xs">
          {invoice.file_size}
        </span>
      </a>

      {invoice.removable && <RemoveInvoiceDialog invoice={invoice} />}
    </div>
  )
}

function RemoveInvoiceDialog({ invoice }: { invoice: ProviderInvoice }) {
  const { t } = useTranslation()
  const [processing, setProcessing] = useState(false)

  function handleRemove() {
    router.delete(providerInvoices.destroy(invoice.id).url, {
      preserveScroll: true,
      onStart: () => setProcessing(true),
      onFinish: () => setProcessing(false),
    })
  }

  return (
    <Dialog>
      <DialogTrigger asChild>
        <Button
          variant="ghost"
          size="icon"
          className="text-muted-foreground"
          aria-label={t("pages.provider_collections.invoice.remove.trigger")}
        >
          <Trash2 aria-hidden="true" />
        </Button>
      </DialogTrigger>

      <DialogContent className="sm:max-w-sm">
        <DialogHeader>
          <DialogTitle>
            {t("pages.provider_collections.invoice.remove.title")}
          </DialogTitle>
          <DialogDescription>
            {t("pages.provider_collections.invoice.remove.description")}
          </DialogDescription>
        </DialogHeader>

        <DialogFooter>
          <DialogClose asChild>
            <Button variant="outline">{t("common.cancel")}</Button>
          </DialogClose>
          <Button disabled={processing} onClick={handleRemove}>
            {processing && <Spinner />}
            {t("pages.provider_collections.invoice.remove.confirm")}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

function UploadInvoice({ account }: { account: ProviderCollectionAccount }) {
  const { t } = useTranslation()
  const { formatMoney } = useFormatters()
  const fileInput = useRef<HTMLInputElement>(null)
  const [open, setOpen] = useState(false)
  const [maxDate, setMaxDate] = useState<string>()

  // Los campos del diálogo se renderizan en un portal, fuera de cualquier
  // <form> de la tarjeta, así que el formulario vive en el estado de useForm.
  const {
    data,
    setData,
    post,
    processing,
    progress,
    errors,
    reset,
    transform,
  } = useForm({
    account_id: account.id,
    file: null as File | null,
    issued_on: "",
    total_amount: String(account.amount),
  })

  const fieldErrors = ["file", "issued_on", "total_amount"]
  const otherErrors = Object.entries(errors)
    .filter(([key]) => !fieldErrors.includes(key))
    .flatMap(([, messages]) => messages ?? [])

  function handleFileChange(event: React.ChangeEvent<HTMLInputElement>) {
    setData("file", event.target.files?.[0] ?? null)
  }

  function handleOpenChange(nextOpen: boolean) {
    if (nextOpen) {
      const date = today()
      setMaxDate(date)
      if (!data.issued_on) setData("issued_on", date)
    }

    setOpen(nextOpen)
  }

  function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()

    transform((data) => ({ invoice: data }))
    post(providerInvoices.create().url, {
      forceFormData: true,
      preserveScroll: true,
      onSuccess: () => {
        setOpen(false)
        reset()
        if (fileInput.current) fileInput.current.value = ""
      },
    })
  }

  return (
    <div className="grid min-w-0 gap-2">
      <label className="bg-background focus-within:border-ring focus-within:ring-ring/50 flex h-10 min-w-0 cursor-pointer items-center gap-3 rounded-md border px-3 text-sm focus-within:ring-[3px]">
        <span className="shrink-0 font-medium">
          {t("pages.provider_collections.invoice.select_file")}
        </span>
        <span className="text-muted-foreground min-w-0 truncate">
          {data.file?.name ?? t("pages.provider_collections.invoice.no_file")}
        </span>
        <input
          ref={fileInput}
          type="file"
          accept=".pdf,.jpg,.jpeg,.png,application/pdf,image/jpeg,image/png"
          aria-label={t("pages.provider_collections.invoice.file_label")}
          className="sr-only"
          onChange={handleFileChange}
        />
      </label>

      <Dialog open={open} onOpenChange={handleOpenChange}>
        <DialogTrigger asChild>
          <Button className="w-full" disabled={!data.file}>
            {t("pages.provider_collections.invoice.upload")}
          </Button>
        </DialogTrigger>

        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>
              {t("pages.provider_collections.invoice.dialog.title")}
            </DialogTitle>
            <DialogDescription>
              {t("pages.provider_collections.invoice.dialog.description", {
                month: account.month,
              })}
            </DialogDescription>
          </DialogHeader>

          <form onSubmit={handleSubmit} className="grid min-w-0 gap-4">
            <Field data-invalid={Boolean(errors.issued_on)}>
              <FieldLabel htmlFor={`invoice-issued-on-${account.id}`}>
                {t("pages.provider_collections.invoice.dialog.issued_on")}
              </FieldLabel>
              <Input
                id={`invoice-issued-on-${account.id}`}
                type="date"
                required
                max={maxDate}
                value={data.issued_on}
                aria-invalid={Boolean(errors.issued_on)}
                onChange={(event) => setData("issued_on", event.target.value)}
              />
              <FieldError
                errors={errors.issued_on?.map((message) => ({ message }))}
              />
            </Field>

            <Field data-invalid={Boolean(errors.total_amount)}>
              <FieldLabel htmlFor={`invoice-total-amount-${account.id}`}>
                {t("pages.provider_collections.invoice.dialog.total_amount")}
              </FieldLabel>
              <Input
                id={`invoice-total-amount-${account.id}`}
                type="number"
                inputMode="decimal"
                min="0.01"
                step="0.01"
                required
                value={data.total_amount}
                aria-invalid={Boolean(errors.total_amount)}
                onChange={(event) =>
                  setData("total_amount", event.target.value)
                }
              />
              <FieldDescription>
                {t("pages.provider_collections.invoice.dialog.expected", {
                  amount: formatMoney(account.amount),
                })}
              </FieldDescription>
              <FieldError
                errors={errors.total_amount?.map((message) => ({ message }))}
              />
            </Field>

            <Field data-invalid={Boolean(errors.file)} className="min-w-0">
              <FieldLabel>
                {t("pages.provider_collections.invoice.dialog.file")}
              </FieldLabel>
              <p className="truncate text-sm">{data.file?.name}</p>
              <FieldDescription>
                {t("pages.provider_collections.invoice.formats")}
              </FieldDescription>
              <FieldError
                errors={errors.file?.map((message) => ({ message }))}
              />
            </Field>

            <FieldError errors={otherErrors.map((message) => ({ message }))} />

            {progress && <Progress value={progress.percentage} />}

            <DialogFooter>
              <DialogClose asChild>
                <Button type="button" variant="outline">
                  {t("common.cancel")}
                </Button>
              </DialogClose>
              <Button type="submit" disabled={processing}>
                {processing && <Spinner />}
                {processing
                  ? t("pages.provider_collections.invoice.uploading")
                  : t("pages.provider_collections.invoice.upload")}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  )
}

export default function InvoiceSection({
  account,
  settled = false,
}: InvoiceSectionProps) {
  const { t } = useTranslation()
  const invoice = account.invoice

  if (settled) {
    if (!invoice) return null

    return (
      <a
        href={providerInvoices.file(invoice.id, { query: { download: 1 } }).url}
        className={cn(buttonVariants({ variant: "outline" }), "w-full")}
      >
        <Download aria-hidden="true" />
        {t("pages.provider_collections.invoice.download")}
      </a>
    )
  }

  return (
    <div className="grid min-w-0 gap-2">
      {invoice && <InvoiceFile invoice={invoice} />}

      {invoice?.status === "rejected" && (
        <p className="text-muted-foreground text-sm">
          {t("pages.provider_collections.invoice.rejected_hint")}
        </p>
      )}

      {(!invoice || invoice.status === "rejected") && (
        <UploadInvoice account={account} />
      )}
    </div>
  )
}
