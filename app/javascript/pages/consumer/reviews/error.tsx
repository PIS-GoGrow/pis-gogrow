import { Head, Link } from "@inertiajs/react"
import { X } from "lucide-react"
import { useTranslation } from "react-i18next"

import { Button } from "@/components/ui/button"
import AppLayout from "@/layouts/app-layout"
import { consumerOrders } from "@/routes"
import type { BreadcrumbItem } from "@/types"

export default function Error() {
  const { t } = useTranslation()

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.orders.index.title"),
      href: consumerOrders.index().url,
    },
    {
      title: t("pages.reviews.error.title"),
      href: consumerOrders.index().url,
    },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t("pages.reviews.error.title")} />

      <div className="mx-auto flex min-h-[70vh] w-full max-w-128 flex-col items-center justify-center gap-6 p-5 text-center">
        <div className="bg-primary text-primary-foreground flex size-16 items-center justify-center rounded-full">
          <X className="size-8" aria-hidden="true" />
        </div>

        <div className="grid gap-2">
          <h1 className="text-2xl font-bold">
            {t("pages.reviews.error.title")}
          </h1>
          <p className="text-muted-foreground">
            {t("pages.reviews.error.description")}
          </p>
        </div>

        <Button size="lg" className="w-full max-w-xs" asChild>
          <Link href={consumerOrders.index().url}>
            {t("pages.reviews.error.close")}
          </Link>
        </Button>
      </div>
    </AppLayout>
  )
}
