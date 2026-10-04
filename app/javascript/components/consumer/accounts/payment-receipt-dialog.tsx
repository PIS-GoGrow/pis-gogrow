import { Form } from "@inertiajs/react"
import { FileText, Trash2 } from "lucide-react"
import type { ComponentProps } from "react"
import { useEffect, useState } from "react"
import { useTranslation } from "react-i18next"

import {
  AdaptableDialog,
  AdaptableDialogContent,
  AdaptableDialogDescription,
  AdaptableDialogHeader,
  AdaptableDialogTitle,
  AdaptableDialogTrigger,
} from "@/components/adaptable-dialog"
import StatusBadge from "@/components/status-badge"
import { Button } from "@/components/ui/button"
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
import { consumerPayments } from "@/routes"
import type { Payment } from "@/types"

interface PaymentReceiptDialogProps {
  accountId: number
  canUpload?: boolean
  payments: Payment[]
  allowDelete?: boolean
  createAction?: ComponentProps<typeof Form>["action"]
  destroyAction?: (paymentId: number) => ComponentProps<typeof Form>["action"]
}

type UploadResult = "success" | "error" | null

export default function PaymentReceiptDialog({
  accountId,
  canUpload = true,
  payments,
  allowDelete = true,
  createAction = consumerPayments.create(),
  destroyAction = consumerPayments.destroy,
}: PaymentReceiptDialogProps) {
  const { t } = useTranslation()
  const receipts = payments.filter((payment) => payment.receipt_url)
  const [open, setOpen] = useState(false)
  const [selectedFile, setSelectedFile] = useState<File | null>(null)
  const [previewUrl, setPreviewUrl] = useState<string | null>(null)
  const [uploadResult, setUploadResult] = useState<UploadResult>(null)

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

  function handleUploadSuccess() {
    handleOpenChange(false)
    setUploadResult("success")
  }

  function handleUploadError() {
    handleOpenChange(false)
    setUploadResult("error")
  }

  return (
    <div className="grid gap-3">
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

          <div className="flex min-w-0 items-center gap-2">
            <FileText aria-hidden="true" className="size-4 shrink-0" />
            <a
              className="block min-w-0 flex-1 overflow-hidden font-medium text-ellipsis whitespace-nowrap hover:underline"
              href={payment.receipt_url}
              download
            >
              {payment.receipt_filename}
            </a>
            {allowDelete &&
              (payment.status === "submitted" ||
                payment.status === "rejected") && (
                <Dialog>
                  <DialogTrigger asChild>
                    <Button
                      aria-label={t("pages.accounts.show.receipt_remove")}
                      size="icon-sm"
                      variant="ghost"
                    >
                      <Trash2 aria-hidden="true" />
                    </Button>
                  </DialogTrigger>

                  <DialogContent>
                    <DialogHeader>
                      <DialogTitle>
                        {t("pages.accounts.show.receipt_remove_title")}
                      </DialogTitle>
                      <DialogDescription>
                        {t("pages.accounts.show.receipt_remove_description")}
                      </DialogDescription>
                    </DialogHeader>

                    <DialogFooter>
                      <DialogClose asChild>
                        <Button type="button" variant="outline">
                          {t("common.cancel")}
                        </Button>
                      </DialogClose>
                      <Form
                        action={destroyAction(payment.id)}
                        method="delete"
                        options={{ preserveScroll: true }}
                      >
                        {({ processing }) => (
                          <Button
                            disabled={processing}
                            type="submit"
                            variant="destructive"
                          >
                            {processing && <Spinner />}
                            {t("pages.accounts.show.receipt_remove_confirm")}
                          </Button>
                        )}
                      </Form>
                    </DialogFooter>
                  </DialogContent>
                </Dialog>
              )}
          </div>
        </div>
      ))}

      <AdaptableDialog open={canUpload && open} onOpenChange={handleOpenChange}>
        {canUpload && (
          <AdaptableDialogTrigger asChild>
            <Button className="w-full">
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
            errorBag={`payment-account-${accountId}`}
            onError={handleUploadError}
            onSuccess={handleUploadSuccess}
            options={{ preserveScroll: true }}
            resetOnSuccess
          >
            {({ errors, processing, progress }) => (
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
                    <p className="text-muted-foreground block max-w-full overflow-hidden border-t px-3 py-2 text-sm text-ellipsis whitespace-nowrap">
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
                    className="w-full min-w-0"
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
        </AdaptableDialogContent>
      </AdaptableDialog>

      <AdaptableDialog
        open={uploadResult !== null}
        onOpenChange={(nextOpen) => {
          if (!nextOpen) setUploadResult(null)
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
                : t("pages.accounts.show.receipt_error_description")}
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
