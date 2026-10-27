import { Sparkles } from "lucide-react"
import type { ReactNode } from "react"
import { useTranslation } from "react-i18next"

export default function AiInsightCard({ children }: { children: ReactNode }) {
  const { t } = useTranslation()

  return (
    <div className="space-y-3 rounded-xl border border-violet-300 bg-gradient-to-br from-[#FCFAFF] to-[#EEF6FF] p-4 text-sm dark:border-violet-900 dark:from-violet-950/30 dark:to-slate-900/30">
      <p>{children}</p>
      <p className="text-muted-foreground flex items-center gap-1.5 text-xs">
        <Sparkles
          className="size-4 shrink-0 text-violet-500"
          aria-hidden="true"
        />
        {t("components.ai_insight_card.generated")}
      </p>
    </div>
  )
}
