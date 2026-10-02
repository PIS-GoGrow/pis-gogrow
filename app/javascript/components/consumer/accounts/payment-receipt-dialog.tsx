import { Form } from "@inertiajs/react"
import { FileText, Trash2 } from "lucide-react"
import { useEffect, useState } from "react"
import { useTranslation } from "react-i18next"

import StatusBadge from "@/components/status-badge"
import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogContent,
  DialogDescription,
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
import { consumerPayments } from "@/routes"
import type { Payment } from "@/types"

interface PaymentReceiptDialogProps {
  accountId: number
  payments: Payment[]
}

export default function PaymentReceiptDialog({
  accountId,
  payments,
}: PaymentReceiptDialogProps) {
  const { t } = useTranslation()
  const receipts = payments.filter((payment) => payment.receipt_url)
  const [open, setOpen] = useState(false)
  const [selectedFile, setSelectedFile] = useState<File | null>(null)
  const [previewUrl, setPreviewUrl] = useState<string | null>(null)

  useEffect(() => {
    return () => {
      if (previewUrl) URL.revokeObjectURL(previewUrl)
    }
  }, [previewUrl])

  function handleOpenChange(nextOpen: boolean) {
    setOpen(nextOpen)

    if (!nextOpen) {
      setSelectedFile(null)
      setPreviewUrl(null)
    }
  }

  function handleFileChange(event: React.ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0] ?? null
    setSelectedFile(file)
    setPreviewUrl(file ? URL.createObjectURL(file) : null)
  }

  return (
    <div className="grid gap-3">
      {receipts.map((payment) => (
        <div
          key={payment.id}
          className="grid min-w-0 gap-2 rounded-md border bg-background p-3 text-sm"
        >
          <div className="flex items-center justify-between gap-2 text-muted-foreground text-xs">
            <span>
              {t("pages.accounts.show.receipt_sent_at", {
                date: payment.receipt_uploaded_at,
              })}
            </span>
            <div className="shrink-0">
              <StatusBadge kind="payment" status={payment.status} />
            </div>
          </div>

          <div className="flex min-w-0 items-center gap-2">
            <FileText aria-hidden="true" className="size-4 shrink-0" />
            <a
              className="block min-w-0 flex-1 overflow-hidden text-ellipsis whitespace-nowrap font-medium hover:underline"
              href={payment.receipt_url}
              download
            >
              {payment.receipt_filename}
            </a>
            {(payment.status === "submitted" ||
              payment.status === "rejected") && (
              <Form
                action={consumerPayments.destroy(payment.id)}
                className="shrink-0"
                method="delete"
                options={{ preserveScroll: true }}
              >
                {({ processing }) => (
                  <Button
                    aria-label={t("pages.accounts.show.receipt_remove")}
                    disabled={processing}
                    size="icon-sm"
                    type="submit"
                    variant="ghost"
                  >
                    {processing ? <Spinner /> : <Trash2 aria-hidden="true" />}
                  </Button>
                )}
              </Form>
            )}
          </div>
        </div>
      ))}

      <Dialog open={open} onOpenChange={handleOpenChange}>
        <DialogTrigger asChild>
          <Button className="w-full">
            {t("pages.accounts.show.receipt")}
          </Button>
        </DialogTrigger>

        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>{t("pages.accounts.show.receipt_title")}</DialogTitle>
            <DialogDescription>
              {t("pages.accounts.show.receipt_description")}
            </DialogDescription>
          </DialogHeader>

          <Form
            action={consumerPayments.create()}
            className="grid min-w-0 gap-3 rounded-lg bg-zinc-100 p-3 dark:bg-zinc-900"
            errorBag={`payment-account-${accountId}`}
            onSuccess={() => handleOpenChange(false)}
            options={{ preserveScroll: true }}
            resetOnSuccess
          >
            {({ errors, processing, progress }) => (
              <>
                {previewUrl && selectedFile && (
                  <div className="overflow-hidden rounded-md border bg-background">
                    {selectedFile.type.startsWith("image/") ? (
                      <img
                        src={previewUrl}
                        alt={t("pages.accounts.show.receipt_preview")}
                        className="max-h-72 w-full object-contain"
                      />
                    ) : (
                      <iframe
                        src={previewUrl}
                        title={t("pages.accounts.show.receipt_preview")}
                        className="h-72 w-full"
                      />
                    )}
                    <p className="block max-w-full overflow-hidden text-ellipsis whitespace-nowrap border-t px-3 py-2 text-sm text-muted-foreground">
                      {selectedFile.name}
                    </p>
                  </div>
                )}

                <input
                  name="payment[account_id]"
                  type="hidden"
                  value={accountId}
                />
                <Field data-invalid={Boolean(errors.receipt)}>
                  <FieldLabel htmlFor={`payment-receipt-${accountId}`}>
                    {t("pages.accounts.show.receipt_file")}
                  </FieldLabel>
                  <Input
                    accept=".pdf,.jpg,.jpeg,.png,application/pdf,image/jpeg,image/png"
                    aria-invalid={Boolean(errors.receipt)}
                    disabled={processing}
                    id={`payment-receipt-${accountId}`}
                    className="min-w-0 w-full"
                    name="payment[receipt]"
                    onChange={handleFileChange}
                    required
                    type="file"
                  />
                  <FieldDescription>
                    {t("pages.accounts.show.receipt_formats")}
                  </FieldDescription>
                  <FieldError
                    errors={errors.receipt?.map((message) => ({ message }))}
                  />
                </Field>

                {progress && <Progress value={progress.percentage} />}

                <Button className="w-full" disabled={processing} type="submit">
                  {processing && <Spinner />}
                  {processing
                    ? t("pages.accounts.show.receipt_uploading")
                    : t("pages.accounts.show.receipt")}
                </Button>
              </>
            )}
          </Form>
        </DialogContent>
      </Dialog>
    </div>
  )
}
