import { Download, Expand } from "lucide-react"
import type { ReactNode } from "react"
import { useTranslation } from "react-i18next"

import {
  AdaptableDialog,
  AdaptableDialogContent,
  AdaptableDialogDescription,
  AdaptableDialogHeader,
  AdaptableDialogTitle,
} from "@/components/adaptable-dialog"
import { Button } from "@/components/ui/button"
import { useFormatters } from "@/hooks/use-formatters"

interface ReceiptSheetProps {
  children: ReactNode
  receiptUrl: string
  contentType?: string | null
  filename?: string
  expectedAmount: number
  notice?: ReactNode
  footer?: ReactNode
  open?: boolean
  onOpenChange?: (open: boolean) => void
}

export default function ReceiptSheet({
  children,
  receiptUrl,
  contentType,
  filename,
  expectedAmount,
  notice,
  footer,
  open,
  onOpenChange,
}: ReceiptSheetProps) {
  const { t } = useTranslation()
  const { formatMoney } = useFormatters()
  const page = "pages.provider_collections.review"
  return (
    <AdaptableDialog
      desktopVariant="sheet"
      open={open}
      onOpenChange={onOpenChange}
    >
      {children}

      <AdaptableDialogContent className="gap-4 sm:max-w-lg">
        <AdaptableDialogHeader>
          <AdaptableDialogTitle>
            {t(`${page}.receipt_title`)}
          </AdaptableDialogTitle>
          <AdaptableDialogDescription>{filename}</AdaptableDialogDescription>
        </AdaptableDialogHeader>

        <div className="min-h-0 overflow-y-auto px-4">
          <dl className="bg-muted mb-4 flex flex-wrap items-baseline gap-x-3 gap-y-1 rounded-lg p-3 text-sm">
            <dt>{t(`${page}.expected_amount`)}</dt>
            <dd className="font-semibold">{formatMoney(expectedAmount)}</dd>
          </dl>
          <div className="bg-background overflow-hidden rounded-xl border">
            <div className="flex flex-wrap justify-end gap-2 p-2">
              <Button asChild variant="outline" size="sm">
                <a href={receiptUrl} download>
                  <Download aria-hidden="true" />
                  {t(`${page}.download`)}
                </a>
              </Button>
              <Button asChild variant="outline" size="icon-sm">
                <a
                  href={receiptUrl}
                  target="_blank"
                  rel="noreferrer"
                  aria-label={t(`${page}.open_receipt`)}
                >
                  <Expand aria-hidden="true" />
                </a>
              </Button>
            </div>
            {contentType?.startsWith("image/") ? (
              <img
                src={receiptUrl}
                alt={t(`${page}.receipt_title`)}
                className="max-h-[40dvh] w-full object-contain"
              />
            ) : (
              <iframe
                src={receiptUrl}
                title={t(`${page}.receipt_title`)}
                className="h-[40dvh] w-full"
              />
            )}
          </div>
          <p className="text-muted-foreground mt-4 text-sm">
            {t(`${page}.check_receipt`)}
          </p>
          {notice && <div className="mt-3">{notice}</div>}
        </div>
        {footer && <div className="mx-4 mb-4 flex gap-3">{footer}</div>}
      </AdaptableDialogContent>
    </AdaptableDialog>
  )
}
