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
  const { bank_name, bank_account_details, beneficiary } = provider

  if (!bank_name || !bank_account_details || !beneficiary) {
    return (
      <p className="text-muted-foreground text-sm">{t(`${page}.missing`)}</p>
    )
  }

  async function copyAccountDetails(details: string) {
    try {
      await navigator.clipboard.writeText(details)
      toast.success(t(`${page}.copied`))
    } catch {
      toast.error(t(`${page}.copy_failed`))
    }
  }

  const accountDetailLines = bank_account_details.split("\n")
  const accountDetails = accountDetailLines
    .map((line) => {
      const account = /^cuenta\s*:\s*(.+)$/i.exec(line)?.[1]
      const number =
        account ??
        (accountDetailLines.length === 1 && !line.includes(":") ? line : null)

      return number ? t(`${page}.account_number`, { number }) : line
    })
    .join("\n")

  return (
    <div className="grid gap-1 rounded-xl border p-4 text-sm">
      <p className="font-medium">{bank_name}</p>
      <div className="text-muted-foreground flex items-start gap-1">
        <p className="whitespace-pre-line">{accountDetails}</p>
        <Button
          variant="ghost"
          size="icon-xs"
          onClick={() => void copyAccountDetails(bank_account_details)}
          aria-label={t(`${page}.copy`)}
        >
          <Copy aria-hidden="true" />
        </Button>
      </div>
      <p className="text-muted-foreground">
        {t(`${page}.beneficiary`, { beneficiary })}
      </p>
    </div>
  )
}
