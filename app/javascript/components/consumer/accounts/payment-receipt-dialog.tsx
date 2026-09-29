import { Form } from "@inertiajs/react"
import { useEffect, useState } from "react"
import { useTranslation } from "react-i18next"

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
  payment?: Payment
}

export default function PaymentReceiptDialog({
  accountId,
  payment,
}: PaymentReceiptDialogProps) {
  const { t } = useTranslation()
  const [open, setOpen] = useState(false)
  const [selectedFile, setSelectedFile] = useState<File | null>(null)
  const [previewUrl, setPreviewUrl] = useState<string | null>(null)
  const isEditable = payment?.status !== "approved"

  useEffect(() => {
    // Las URLs locales sólo existen para previsualizar el archivo antes de subirlo.
    return () => {
      if (previewUrl) URL.revokeObjectURL(previewUrl)
    }
  }, [previewUrl])

  const action = payment
    ? consumerPayments.update(payment.id)
    : consumerPayments.create()
  const displayedUrl = previewUrl ?? payment?.receipt_url
  const displayedType = selectedFile?.type ?? payment?.receipt_content_type
  const displayedFilename = selectedFile?.name ?? payment?.receipt_filename

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
    // Al editar, la vista previa local sustituye visualmente al comprobante guardado.
    setPreviewUrl(file ? URL.createObjectURL(file) : null)
  }

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogTrigger asChild>
        <Button
          className="w-full"
          variant={payment?.receipt_url ? "outline" : "default"}
        >
          {payment?.receipt_url
            ? t("pages.accounts.show.receipt_view_edit")
            : t("pages.accounts.show.receipt")}
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
          action={action}
          errorBag={`payment-${payment?.id ?? `account-${accountId}`}`}
          options={{ preserveScroll: true }}
          resetOnSuccess
          onSuccess={() => handleOpenChange(false)}
          className="rounded-lg bg-zinc-100 p-3 dark:bg-zinc-900"
        >
          {({ errors, processing, progress }) => (
            <div className="space-y-3">
              {displayedUrl && (
                <div className="bg-background overflow-hidden rounded-md border">
                  {displayedType?.startsWith("image/") ? (
                    <img
                      src={displayedUrl}
                      alt={t("pages.accounts.show.receipt_preview")}
                      className="max-h-72 w-full object-contain"
                    />
                  ) : (
                    <iframe
                      src={displayedUrl}
                      title={t("pages.accounts.show.receipt_preview")}
                      className="h-72 w-full"
                    />
                  )}
                  {displayedFilename && (
                    <p className="text-muted-foreground truncate border-t px-3 py-2 text-sm">
                      {displayedFilename}
                    </p>
                  )}
                </div>
              )}

              {!payment && (
                <input
                  type="hidden"
                  name="payment[account_id]"
                  value={accountId}
                />
              )}

              {isEditable && (
                <Field data-invalid={Boolean(errors.receipt)}>
                  <FieldLabel htmlFor={`payment-receipt-${accountId}`}>
                    {payment?.receipt_url
                      ? t("pages.accounts.show.receipt_replace")
                      : t("pages.accounts.show.receipt_file")}
                  </FieldLabel>
                  <Input
                    id={`payment-receipt-${accountId}`}
                    name="payment[receipt]"
                    type="file"
                    accept=".pdf,.jpg,.jpeg,.png,application/pdf,image/jpeg,image/png"
                    required
                    disabled={processing}
                    aria-invalid={Boolean(errors.receipt)}
                    className="bg-background"
                    onChange={handleFileChange}
                  />
                  <FieldDescription>
                    {t("pages.accounts.show.receipt_formats")}
                  </FieldDescription>
                  <FieldError
                    errors={errors.receipt?.map((message) => ({ message }))}
                  />
                </Field>
              )}

              {progress && <Progress value={progress.percentage} />}

              {isEditable ? (
                <Button type="submit" disabled={processing} className="w-full">
                  {processing && <Spinner />}
                  {processing
                    ? t("pages.accounts.show.receipt_uploading")
                    : payment?.receipt_url
                      ? t("pages.accounts.show.receipt_update")
                      : t("pages.accounts.show.receipt")}
                </Button>
              ) : (
                <p className="text-muted-foreground text-center text-sm">
                  {t("pages.accounts.show.receipt_approved")}
                </p>
              )}
            </div>
          )}
        </Form>
      </DialogContent>
    </Dialog>
  )
}
