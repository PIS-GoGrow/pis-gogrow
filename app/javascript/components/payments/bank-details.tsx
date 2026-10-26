import { Copy } from "lucide-react"
import { useTranslation } from "react-i18next"
import { toast } from "sonner"

import { Button } from "@/components/ui/button"
import type { PaymentProvider } from "@/types"

interface BankDetailsProps {
  provider: PaymentProvider
}

const page = "pages.admin.payments.index.bank"

export default function BankDetails({ provider }: BankDetailsProps) {
  const { t } = useTranslation()
  const { bank_name, bank_account_number, bank_account_holder } = provider

  if (!bank_name || !bank_account_number || !bank_account_holder) {
    return (
      <p className="text-muted-foreground text-sm">{t(`${page}.missing`)}</p>
    )
  }

  async function copyAccountNumber(number: string) {
    try {
      await navigator.clipboard.writeText(number)
      toast.success(t(`${page}.copied`))
    } catch {
      toast.error(t(`${page}.copy_failed`))
    }
  }

  return (
    <div className="grid gap-1 rounded-xl border p-4 text-sm">
      <p className="font-medium">{bank_name}</p>
      <p className="text-muted-foreground flex items-center gap-1">
        {t(`${page}.account_number`, { number: bank_account_number })}
        <Button
          variant="ghost"
          size="icon-xs"
          onClick={() => void copyAccountNumber(bank_account_number)}
          aria-label={t(`${page}.copy`)}
        >
          <Copy aria-hidden="true" />
        </Button>
      </p>
      <p className="text-muted-foreground">
        {t(`${page}.holder`, { holder: bank_account_holder })}
      </p>
    </div>
  )
}
