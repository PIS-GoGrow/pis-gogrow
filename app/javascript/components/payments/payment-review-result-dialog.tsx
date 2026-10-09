import { useTranslation } from "react-i18next"

import {
  AdaptableDialog,
  AdaptableDialogContent,
  AdaptableDialogDescription,
  AdaptableDialogTitle,
} from "@/components/adaptable-dialog"
import type { PaymentReviewResult } from "@/components/payments/payment-review-result-context"
import { Button } from "@/components/ui/button"

interface PaymentReviewResultDialogProps {
  result: PaymentReviewResult | null
  onClose: () => void
}

// Vive en la página, no en PaymentReviewSheet: ver payment-review-result-context.
export default function PaymentReviewResultDialog({
  result,
  onClose,
}: PaymentReviewResultDialogProps) {
  const { t } = useTranslation()

  const copy =
    result &&
    {
      approved: {
        title: t("pages.provider_collections.review.approved_title"),
        description: t(
          "pages.provider_collections.review.approved_description",
        ),
      },
      partial: {
        title: t("pages.provider_collections.review.partial_title"),
        description: t("pages.provider_collections.review.partial_description"),
      },
      rejected: {
        title: t("pages.provider_collections.review.rejected_title"),
        description: t(
          "pages.provider_collections.review.rejected_description",
        ),
      },
    }[result]

  return (
    <AdaptableDialog
      open={result !== null}
      onOpenChange={(nextOpen) => {
        if (!nextOpen) onClose()
      }}
    >
      <AdaptableDialogContent showCloseButton={false} className="p-5">
        <div className="flex flex-col gap-5">
          <AdaptableDialogTitle className="text-base leading-6 font-semibold tracking-normal">
            {copy?.title}
          </AdaptableDialogTitle>
          <AdaptableDialogDescription className="text-base leading-6">
            {copy?.description}
          </AdaptableDialogDescription>
          <Button
            type="button"
            className="h-12 w-full rounded-lg text-base font-medium"
            onClick={onClose}
          >
            {t("pages.provider_collections.review.done")}
          </Button>
        </div>
      </AdaptableDialogContent>
    </AdaptableDialog>
  )
}
