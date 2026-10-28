import { Form } from "@inertiajs/react"
import { FileText, Trash2, X } from "lucide-react"
import type { ComponentProps } from "react"
import { useEffect, useId, useState } from "react"
import { useTranslation } from "react-i18next"

import {
  AdaptableDialog,
  AdaptableDialogClose,
  AdaptableDialogContent,
  AdaptableDialogDescription,
  AdaptableDialogFooter,
  AdaptableDialogHeader,
  AdaptableDialogTitle,
  AdaptableDialogTrigger,
} from "@/components/adaptable-dialog"
import { FileInput } from "@/components/file-input"
import StatusBadge from "@/components/status-badge"
import { Button } from "@/components/ui/button"
import {
  Field,
  FieldDescription,
  FieldError,
  FieldLabel,
} from "@/components/ui/field"
import { Progress } from "@/components/ui/progress"
import { Spinner } from "@/components/ui/spinner"
import { formatFileSize } from "@/lib/format-file-size"
import { consumerPayments } from "@/routes"
import type { Payment } from "@/types"

interface PaymentReceiptDialogProps {
  accountId: number
  canUpload?: boolean
  // Se muestra el botón pero deshabilitado, por ej. mientras hay un comprobante
  // en revisión: la cuenta solo admite uno a la vez.
  uploadDisabled?: boolean
  payments: Payment[]
  allowDelete?: boolean
  inlineUpload?: boolean
  createAction?: ComponentProps<typeof Form>["action"]
  destroyAction?: (paymentId: number) => ComponentProps<typeof Form>["action"]
}

type UploadResult = "success" | "error" | null

export default function PaymentReceiptDialog({
  accountId,
  canUpload = true,
  uploadDisabled = false,
  payments,
  allowDelete = true,
  inlineUpload = false,
  createAction = consumerPayments.create(),
  destroyAction = consumerPayments.destroy,
}: PaymentReceiptDialogProps) {
  const { t } = useTranslation()
  const uploadHintId = useId()
  const receipts = payments.filter((payment) => payment.receipt_url)
  const [open, setOpen] = useState(false)
  const [selectedFile, setSelectedFile] = useState<File | null>(null)
  const [previewUrl, setPreviewUrl] = useState<string | null>(null)
  const [uploadResult, setUploadResult] = useState<UploadResult>(null)
  const [uploadErrorMessage, setUploadErrorMessage] = useState<string | null>(
    null,
  )
  const [fileMissing, setFileMissing] = useState(false)
  const [inputKey, setInputKey] = useState(0)

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
      setFileMissing(false)
    }
  }

  function handleFileChange(event: React.ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0] ?? null
    setSelectedFile(file)
    setPreviewUrl(file && !inlineUpload ? URL.createObjectURL(file) : null)
    setFileMissing(false)
  }

  function clearFile() {
    setSelectedFile(null)
    setInputKey((key) => key + 1)
  }

  function handleBeforeUpload() {
    if (selectedFile) return true

    setFileMissing(true)
    return false
  }

  function handleUploadSuccess() {
    handleOpenChange(false)
    setUploadResult("success")
  }

  function handleUploadError(errors: Record<string, string | string[]>) {
    setUploadErrorMessage([errors.receipt].flat()[0] ?? null)
    handleOpenChange(false)
    setInputKey((key) => key + 1)
    setUploadResult("error")
  }

  return (
    <div className="grid min-w-0 grid-cols-1 gap-3">
      {receipts.map((payment) => (
        <div
          key={payment.id}
          className="bg-background grid min-w-0 gap-2 rounded-md border p-3 text-sm"
        >
          <div className="text-muted-foreground flex items-center justify-between gap-2 text-xs">
            <span>
              {t("pages.accounts.show.receipt_sent_at", {
                date: payment.receipt_uploaded_at,
              })}
            </span>
            <div className="shrink-0">
              <StatusBadge kind="payment" status={payment.status} />
            </div>
          </div>

          <div className="flex min-w-0 items-center gap-3">
            <div className="bg-muted flex size-10 shrink-0 items-center justify-center rounded-md">
              <FileText aria-hidden="true" className="size-4" />
            </div>
            <div className="min-w-0 flex-1">
              <a
                className="block overflow-hidden font-medium text-ellipsis whitespace-nowrap hover:underline"
                href={payment.receipt_url}
                download
              >
                {payment.receipt_filename}
              </a>
              {payment.receipt_byte_size != null && (
                <p className="text-muted-foreground text-xs">
                  {formatFileSize(payment.receipt_byte_size)}
                </p>
              )}
            </div>
            {allowDelete &&
              (payment.status === "submitted" ||
                payment.status === "rejected") && (
                <AdaptableDialog>
                  <AdaptableDialogTrigger asChild>
                    <Button
                      aria-label={t("pages.accounts.show.receipt_remove")}
                      size="icon-sm"
                      variant="ghost"
                    >
                      <Trash2 aria-hidden="true" />
                    </Button>
                  </AdaptableDialogTrigger>

                  <AdaptableDialogContent
                    showCloseButton={false}
                    className="p-5 md:p-6"
                  >
                    <AdaptableDialogHeader className="p-0">
                      <AdaptableDialogTitle>
                        {t("pages.accounts.show.receipt_remove_title")}
                      </AdaptableDialogTitle>
                      <AdaptableDialogDescription>
                        {t("pages.accounts.show.receipt_remove_description")}
                      </AdaptableDialogDescription>
                    </AdaptableDialogHeader>

                    <AdaptableDialogFooter className="p-0 max-md:flex-row max-md:gap-3">
                      <AdaptableDialogClose asChild>
                        <Button
                          type="button"
                          variant="outline"
                          className="max-md:flex-1"
                        >
                          {t("common.cancel")}
                        </Button>
                      </AdaptableDialogClose>
                      <Form
                        action={destroyAction(payment.id)}
                        className="max-md:flex-1"
                        method="delete"
                        options={{ preserveScroll: true }}
                      >
                        {({ processing }) => (
                          <Button
                            disabled={processing}
                            type="submit"
                            className="max-md:w-full"
                          >
                            {processing && <Spinner />}
                            {t("pages.accounts.show.receipt_remove_confirm")}
                          </Button>
                        )}
                      </Form>
                    </AdaptableDialogFooter>
                  </AdaptableDialogContent>
                </AdaptableDialog>
              )}
          </div>
        </div>
      ))}

      {inlineUpload ? (
        canUpload &&
        !uploadDisabled && (
          <Form
            action={createAction}
            className="grid min-w-0 grid-cols-1 gap-3"
            noValidate
            onBefore={handleBeforeUpload}
            onError={handleUploadError}
            onSuccess={handleUploadSuccess}
            options={{ preserveScroll: true }}
            resetOnSuccess
          >
            {({ errors, processing }) => {
              const receiptErrors = errors.receipt ?? []

              return (
                <>
                  <input
                    name="payment[account_id]"
                    type="hidden"
                    value={accountId}
                  />
                  {selectedFile && (
                    <div className="bg-background flex min-w-0 items-center gap-3 rounded-md border p-3 text-sm">
                      <div className="bg-muted flex size-10 shrink-0 items-center justify-center rounded-md">
                        <FileText aria-hidden="true" className="size-4" />
                      </div>
                      <div className="min-w-0 flex-1">
                        <p className="truncate font-medium">
                          {selectedFile.name}
                        </p>
                        <p className="text-muted-foreground text-xs">
                          {formatFileSize(selectedFile.size)}
                        </p>
                      </div>
                      <Button
                        aria-label={t("pages.accounts.show.receipt_clear")}
                        disabled={processing}
                        onClick={clearFile}
                        size="icon-sm"
                        type="button"
                        variant="ghost"
                      >
                        <X aria-hidden="true" />
                      </Button>
                    </div>
                  )}
                  <Field
                    className="min-w-0"
                    data-invalid={receiptErrors.length > 0}
                  >
                    <FieldLabel
                      className="sr-only"
                      htmlFor={`payment-receipt-${accountId}`}
                    >
                      {t("pages.accounts.show.receipt_file")}
                    </FieldLabel>
                    <FileInput
                      accept=".pdf,.jpg,.jpeg,.png,application/pdf,image/jpeg,image/png"
                      aria-invalid={receiptErrors.length > 0}
                      className={selectedFile ? "hidden" : undefined}
                      disabled={processing}
                      id={`payment-receipt-${accountId}`}
                      key={inputKey}
                      name="payment[receipt]"
                      onChange={handleFileChange}
                    />
                    <FieldError
                      errors={receiptErrors.map((message) => ({ message }))}
                    />
                  </Field>

                  <Button
                    className="w-full"
                    disabled={processing || !selectedFile}
                    type="submit"
                  >
                    {processing && <Spinner />}
                    {processing
                      ? t("pages.accounts.show.receipt_uploading")
                      : t("pages.accounts.show.receipt")}
                  </Button>
                </>
              )
            }}
          </Form>
        )
      ) : (
        <AdaptableDialog
          open={canUpload && !uploadDisabled && open}
          onOpenChange={handleOpenChange}
        >
          {canUpload && (
            <AdaptableDialogTrigger asChild>
              <Button
                className="w-full"
                disabled={uploadDisabled}
                aria-describedby={uploadDisabled ? uploadHintId : undefined}
              >
                {t("pages.accounts.show.receipt")}
              </Button>
            </AdaptableDialogTrigger>
          )}

          <AdaptableDialogContent className="p-5">
            <AdaptableDialogHeader className="px-0 py-2">
              <AdaptableDialogTitle>
                {t("pages.accounts.show.receipt_title")}
              </AdaptableDialogTitle>
              <AdaptableDialogDescription>
                {t("pages.accounts.show.receipt_description")}
              </AdaptableDialogDescription>
            </AdaptableDialogHeader>

            <Form
              action={createAction}
              className="grid min-w-0 gap-3 rounded-lg bg-zinc-100 p-3 dark:bg-zinc-900"
              noValidate
              onBefore={handleBeforeUpload}
              onError={handleUploadError}
              onSuccess={handleUploadSuccess}
              options={{ preserveScroll: true }}
              resetOnSuccess
            >
              {({ errors, processing, progress }) => {
                const receiptErrors = [
                  ...(fileMissing
                    ? [t("pages.accounts.show.receipt_required")]
                    : []),
                  ...(errors.receipt ?? []),
                ]

                return (
                  <>
                    {previewUrl && selectedFile && (
                      <div className="bg-background overflow-hidden rounded-md border">
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
                      </div>
                    )}

                    <input
                      name="payment[account_id]"
                      type="hidden"
                      value={accountId}
                    />
                    <Field data-invalid={receiptErrors.length > 0}>
                      <FieldLabel htmlFor={`payment-receipt-${accountId}`}>
                        {t("pages.accounts.show.receipt_file")}
                      </FieldLabel>
                      <FileInput
                        accept=".pdf,.jpg,.jpeg,.png,application/pdf,image/jpeg,image/png"
                        aria-invalid={receiptErrors.length > 0}
                        disabled={processing}
                        fileName={selectedFile?.name}
                        id={`payment-receipt-${accountId}`}
                        name="payment[receipt]"
                        onChange={handleFileChange}
                      />
                      <FieldDescription>
                        {t("pages.accounts.show.receipt_formats")}
                      </FieldDescription>
                      <FieldError
                        errors={receiptErrors.map((message) => ({ message }))}
                      />
                    </Field>

                    {progress && <Progress value={progress.percentage} />}

                    <Button
                      className="w-full"
                      disabled={processing}
                      type="submit"
                    >
                      {processing && <Spinner />}
                      {processing
                        ? t("pages.accounts.show.receipt_uploading")
                        : t("pages.accounts.show.receipt")}
                    </Button>
                  </>
                )
              }}
            </Form>
          </AdaptableDialogContent>
        </AdaptableDialog>
      )}

      {!inlineUpload && canUpload && uploadDisabled && (
        <p id={uploadHintId} className="text-muted-foreground text-sm">
          {t("pages.accounts.show.receipt_under_review_hint")}
        </p>
      )}

      <AdaptableDialog
        open={uploadResult !== null}
        onOpenChange={(nextOpen) => {
          if (!nextOpen) {
            setUploadResult(null)
            setUploadErrorMessage(null)
          }
        }}
      >
        <AdaptableDialogContent showCloseButton={false} className="p-5">
          <div className="flex flex-col gap-5">
            <AdaptableDialogTitle className="text-base leading-6 font-semibold tracking-normal">
              {uploadResult === "success"
                ? t("pages.accounts.show.receipt_success_title")
                : t("pages.accounts.show.receipt_error_title")}
            </AdaptableDialogTitle>
            <AdaptableDialogDescription className="text-base leading-6">
              {uploadResult === "success"
                ? t("pages.accounts.show.receipt_success_description")
                : (uploadErrorMessage ??
                  t("pages.accounts.show.receipt_error_description"))}
            </AdaptableDialogDescription>
            <Button
              type="button"
              className="h-12 w-full rounded-lg text-base font-medium"
              onClick={() => setUploadResult(null)}
            >
              {uploadResult === "success"
                ? t("pages.accounts.show.receipt_success_action")
                : t("pages.accounts.show.receipt_error_action")}
            </Button>
          </div>
        </AdaptableDialogContent>
      </AdaptableDialog>
    </div>
  )
}
