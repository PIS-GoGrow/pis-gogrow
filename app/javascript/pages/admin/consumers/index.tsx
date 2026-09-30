import { Head, Link } from "@inertiajs/react"
import { Search, Users } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import ConsumptionStatusBadge from "@/components/admin/consumption-status-badge"
import ListItemCard from "@/components/list-item-card"
import PageContainer from "@/components/page-container"
import { Avatar, AvatarFallback } from "@/components/ui/avatar"
import { CardContent } from "@/components/ui/card"
import {
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyMedia,
  EmptyTitle,
} from "@/components/ui/empty"
import { Input } from "@/components/ui/input"
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group"
import { useFormatters } from "@/hooks/use-formatters"
import { useInitials } from "@/hooks/use-initials"
import AppLayout from "@/layouts/app-layout"
import { adminConsumers } from "@/routes"
import type {
  AdminConsumerRow,
  AdminConsumersIndex,
  BreadcrumbItem,
} from "@/types"

type Filter = "all" | "pending" | "completed"

const page = "pages.admin.consumers.index"

export default function Index({ consumers }: AdminConsumersIndex) {
  const { t } = useTranslation()
  const { formatMoney } = useFormatters()
  const getInitials = useInitials()
  const [filter, setFilter] = useState<Filter>("all")
  const [search, setSearch] = useState("")

  const term = search.trim().toLowerCase()

  // Completado es un mes cerrado: ya pagó o no tuvo nada que pagar.
  const completed = (status: AdminConsumerRow["status"]) =>
    !status || status === "approved"

  const shown = consumers.filter((consumer) => {
    if (filter === "pending" && completed(consumer.status)) return false
    if (filter === "completed" && !completed(consumer.status)) return false

    return (
      term === "" ||
      consumer.name.toLowerCase().includes(term) ||
      consumer.email.toLowerCase().includes(term)
    )
  })

  const emptyKey = consumers.length === 0 ? "empty" : "no_results"

  const breadcrumbs: BreadcrumbItem[] = [
    { title: t(`${page}.title`), href: adminConsumers.index().url },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t(`${page}.title`)} />

      <PageContainer
        title={t(`${page}.title`)}
        description={t(`${page}.count`, { count: shown.length })}
      >
        <ToggleGroup
          type="single"
          variant="outline"
          value={filter}
          // Radix manda "" al destildar la opción activa; el filtro siempre tiene una.
          onValueChange={(value) => value && setFilter(value as Filter)}
          aria-label={t(`${page}.filter_label`)}
          className="w-full"
        >
          <ToggleGroupItem value="all" className="flex-1">
            {t(`${page}.all`)}
          </ToggleGroupItem>
          <ToggleGroupItem value="completed" className="flex-1">
            {t(`${page}.completed`)}
          </ToggleGroupItem>
          <ToggleGroupItem value="pending" className="flex-1">
            {t(`${page}.pending`)}
          </ToggleGroupItem>
        </ToggleGroup>

        <div className="relative">
          <Search
            className="text-muted-foreground pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2"
            aria-hidden="true"
          />
          <Input
            type="search"
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            placeholder={t(`${page}.search_placeholder`)}
            aria-label={t(`${page}.search_label`)}
            className="pl-9"
          />
        </div>

        {shown.length === 0 ? (
          <Empty className="border">
            <EmptyHeader>
              <EmptyMedia variant="icon">
                <Users aria-hidden="true" />
              </EmptyMedia>
              <EmptyTitle>{t(`${page}.${emptyKey}_title`)}</EmptyTitle>
              <EmptyDescription>
                {t(`${page}.${emptyKey}_description`)}
              </EmptyDescription>
            </EmptyHeader>
          </Empty>
        ) : (
          <div className="grid gap-4 md:grid-cols-2">
            {shown.map((consumer) => (
              <ListItemCard
                key={consumer.id}
                className="hover:bg-accent/40 focus-within:ring-ring/50 relative transition-colors focus-within:ring-[3px]"
              >
                <CardContent className="flex items-center gap-3">
                  <Avatar size="lg">
                    <AvatarFallback className="text-foreground text-xs font-semibold">
                      {getInitials(consumer.name)}
                    </AvatarFallback>
                  </Avatar>

                  <div className="min-w-0 flex-1">
                    <p className="truncate font-medium">
                      <Link
                        href={adminConsumers.show(consumer.id).url}
                        className="after:absolute after:inset-0 hover:underline"
                      >
                        {consumer.name}
                      </Link>
                    </p>
                    <p className="text-muted-foreground truncate text-sm">
                      {consumer.email}
                    </p>
                  </div>

                  <div className="flex shrink-0 items-center gap-3">
                    <span className="font-semibold">
                      {formatMoney(consumer.amount)}
                    </span>
                    <ConsumptionStatusBadge status={consumer.status} />
                  </div>
                </CardContent>
              </ListItemCard>
            ))}
          </div>
        )}
      </PageContainer>
    </AppLayout>
  )
}
