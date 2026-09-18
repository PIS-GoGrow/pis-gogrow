import { Head, Link, router } from "@inertiajs/react"
import { Search } from "lucide-react"
import { type FormEvent, useState } from "react"
import { useTranslation } from "react-i18next"

import { Button } from "@/components/ui/button"
import {
  Card,
  CardContent,
  CardDescription,
  CardTitle,
} from "@/components/ui/card"
import {
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyTitle,
} from "@/components/ui/empty"
import { Input } from "@/components/ui/input"
import AppLayout from "@/layouts/app-layout"
import { adminConsumers } from "@/routes"
import type { AdminConsumersIndex, BreadcrumbItem } from "@/types"

export default function Index({ query, consumers }: AdminConsumersIndex) {
  const { t } = useTranslation()
  const [search, setSearch] = useState(query)

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.admin.consumers.index.title"),
      href: adminConsumers.index().url,
    },
  ]

  function handleSubmit(event: FormEvent) {
    event.preventDefault()
    router.get(
      adminConsumers.index().url,
      { query: search },
      { preserveState: true, replace: true },
    )
  }

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t("pages.admin.consumers.index.title")} />

      <div className="mx-auto grid w-full max-w-3xl gap-6 p-5">
        <h1 className="text-2xl font-bold">
          {t("pages.admin.consumers.index.title")}
        </h1>

        <form onSubmit={handleSubmit} className="flex gap-2">
          <Input
            type="search"
            name="query"
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            placeholder={t("pages.admin.consumers.index.search_placeholder")}
            className="max-w-sm"
          />
          <Button type="submit">
            <Search aria-hidden="true" />
            {t("pages.admin.consumers.index.search_button")}
          </Button>
        </form>

        {consumers.length === 0 ? (
          <Empty>
            <EmptyHeader>
              <EmptyTitle>
                {t("pages.admin.consumers.index.empty_title")}
              </EmptyTitle>
              <EmptyDescription>
                {t("pages.admin.consumers.index.empty_description")}
              </EmptyDescription>
            </EmptyHeader>
          </Empty>
        ) : (
          <div className="grid gap-3">
            {consumers.map((consumer) => (
              <Card
                key={consumer.id}
                className="hover:bg-accent/40 focus-within:ring-ring/50 relative gap-2 py-4 transition-colors focus-within:ring-[3px]"
              >
                <CardContent className="flex items-center justify-between gap-3 px-4">
                  <div>
                    <CardTitle>
                      <Link
                        href={adminConsumers.show(consumer.id).url}
                        className="after:absolute after:inset-0 hover:underline"
                      >
                        {consumer.name}
                      </Link>
                    </CardTitle>
                    <CardDescription>{consumer.email}</CardDescription>
                  </div>

                  <span className="text-muted-foreground shrink-0 text-sm">
                    {consumer.company_name}
                  </span>
                </CardContent>
              </Card>
            ))}
          </div>
        )}
      </div>
    </AppLayout>
  )
}
