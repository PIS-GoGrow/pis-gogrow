import type { ReactNode } from "react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import EditBenefitConfigurationForm from "@/components/benefit-configurations/edit-benefit-configuration-form"
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import type { BenefitConfiguration } from "@/types/serializers"

interface EditBenefitConfigurationDialogProps {
  children: ReactNode
  currentBenefitConfiguration: BenefitConfiguration | null
}

export default function EditBenefitConfigurationDialog({
  children,
  currentBenefitConfiguration,
}: EditBenefitConfigurationDialogProps) {
  const { t } = useTranslation()
  const [open, setOpen] = useState(false)

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      {children}

      <DialogContent>
        <DialogHeader>
          <DialogTitle>
            {t("pages.admin.benefit_configurations.index.edit.title")}
          </DialogTitle>
        </DialogHeader>

        <EditBenefitConfigurationForm
          defaultValues={{
            subsidy_percentage:
              currentBenefitConfiguration?.subsidy_percentage ?? "",
            max_voucher_price:
              currentBenefitConfiguration?.max_voucher_price ?? "",
            monthly_voucher_limit:
              currentBenefitConfiguration?.monthly_voucher_limit ?? "",
          }}
          onCancel={() => setOpen(false)}
          onSuccess={() => setOpen(false)}
        />
      </DialogContent>
    </Dialog>
  )
}
