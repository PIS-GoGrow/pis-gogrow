import { Link } from "@inertiajs/react"
import { X } from "lucide-react"
import { useTranslation } from "react-i18next"

import { BottomAction, MobileCard } from "@/components/consumer/mobile-card"
import { Button } from "@/components/ui/button"
import { consumerDashboard } from "@/routes"

interface Props {
  retry: () => void
  error?: string
}

export function OrderError({ retry, error }: Props) {
  const { t } = useTranslation()

  return (
    <MobileCard>
      <div className="flex flex-1 flex-col items-center justify-center py-8">
        <div className="bg-primary text-primary-foreground flex size-20 items-center justify-center rounded-full">
          <X aria-hidden="true" className="size-10" strokeWidth={2.5} />
        </div>

        <h1 className="mt-7 text-center text-2xl font-bold">
          {t("pages.cart.order_error.title")}
        </h1>

        <p className="text-muted-foreground mt-2 max-w-sm text-center text-base leading-6 whitespace-pre-line">
          {error ?? t("pages.cart.order_error.description")}
        </p>
      </div>

      <BottomAction className="flex">
        <Button
          asChild
          type="button"
          onClick={retry}
          className="bg-primary text-primary-foreground hover:bg-primary/90 hover:text-primary-foreground h-12 flex-1"
        >
          <Link href={consumerDashboard.cart().url} preserveState={false} role="button">
            {t("pages.cart.order_error.retry")}
          </Link>
        </Button>

        <Button
          asChild
          type="button"
          variant="secondary"
          className="bg-secondary text-secondary-foreground hover:bg-secondary/80 hover:text-secondary-foreground h-12 flex-1"
        >
          <Link href={consumerDashboard.index().url} preserveState={false}>
            {t("pages.cart.order_error.menu")}
          </Link>
        </Button>
      </BottomAction>
    </MobileCard>
  )
}
