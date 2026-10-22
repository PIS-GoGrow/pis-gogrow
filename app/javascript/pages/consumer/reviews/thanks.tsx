import { Head, Link } from "@inertiajs/react"
import { Check } from "lucide-react"
import { useTranslation } from "react-i18next"

import ReviewActions from "@/components/reviews/review-actions"
import ReviewPage from "@/components/reviews/review-page"
import { Button } from "@/components/ui/button"
import AppLayout from "@/layouts/app-layout"
import { consumerOrders } from "@/routes"
import type { BreadcrumbItem } from "@/types"

export default function Thanks() {
  const { t } = useTranslation()

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.orders.index.title"),
      href: consumerOrders.index().url,
    },
    {
      title: t("pages.reviews.thanks.title"),
      href: consumerOrders.index().url,
    },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t("pages.reviews.thanks.title")} />

      <ReviewPage>
        <div className="flex min-h-0 flex-1 flex-col items-center justify-center gap-8 overflow-y-auto px-6 py-8 text-center">
          <div className="text-foreground flex size-20 shrink-0 items-center justify-center rounded-full border-2 border-current">
            <Check className="size-10" strokeWidth={2.5} aria-hidden="true" />
          </div>

          <div className="grid w-full max-w-88 gap-3">
            <h1 className="text-2xl font-bold">
              {t("pages.reviews.thanks.title")}
            </h1>
            <p className="text-muted-foreground text-base leading-relaxed">
              {t("pages.reviews.thanks.description")}
            </p>
          </div>
        </div>
        <ReviewActions>
          <Button size="lg" className="w-full" asChild>
            <Link href={consumerOrders.index().url}>
              {t("pages.reviews.thanks.close")}
            </Link>
          </Button>
        </ReviewActions>
      </ReviewPage>
    </AppLayout>
  )
}
