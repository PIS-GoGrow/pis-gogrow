import { Head, Link, router } from "@inertiajs/react"
import { X } from "lucide-react"
import { useTranslation } from "react-i18next"

import { Button } from "@/components/ui/button"
import { home } from "@/routes"

export default function InternalServerError() {
  const { t } = useTranslation()

  return (
    <>
      <Head title={t("pages.errors.internal_server_error.title")} />

      <main className="bg-background text-foreground flex min-h-svh flex-col px-6 py-8 md:mx-auto md:my-8 md:min-h-0 md:max-w-3xl md:rounded-2xl md:border md:p-8">
        <div className="flex flex-1 flex-col items-center justify-center pb-16">
          <div className="bg-primary text-primary-foreground flex size-20 items-center justify-center rounded-full">
            <X aria-hidden="true" className="size-10" strokeWidth={2.5} />
          </div>

          <h1 className="mt-7 text-center text-2xl font-bold">
            {t("pages.errors.internal_server_error.heading")}
          </h1>
          <p className="text-muted-foreground mt-2 max-w-sm text-center text-base leading-6">
            {t("pages.errors.internal_server_error.description")}
          </p>
        </div>

        <div className="space-y-3">
          <Button className="h-12 w-full" onClick={() => router.reload()}>
            {t("pages.errors.internal_server_error.retry")}
          </Button>
          <Button asChild variant="secondary" className="h-12 w-full">
            <Link href={home.index()}>
              {t("pages.errors.internal_server_error.back_home")}
            </Link>
          </Button>
        </div>
      </main>
    </>
  )
}
