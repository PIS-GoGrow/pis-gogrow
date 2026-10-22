import { Head, Link, router } from "@inertiajs/react"
import { Search, Users } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import ConsumptionStatusBadge from "@/components/admin/consumption-status-badge"
import MonthSelect from "@/components/admin/month-select"
import ListItemCard from "@/components/list-item-card"
import PageContainer from "@/components/page-container"
import { Avatar, AvatarFallback } from "@/components/ui/avatar"
import { Badge } from "@/components/ui/badge"
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

type Filter = AdminConsumersIndex["filter"]

const page = "pages.admin.consumers.index"

// El control segmentado del diseño, igual a las pestañas de Pagos.
const segment =
  "data-[state=on]:bg-background flex-1 rounded-md data-[state=on]:shadow-sm"

export default function Index({
  consumers,
  filter: initialFilter,
  month,
  current_month,
  months,
}: AdminConsumersIndex) {
  const { t } = useTranslation()
  const { formatMoney } = useFormatters()
  const getInitials = useInitials()
  const [filter, setFilter] = useState<Filter>(initialFilter)
  const [search, setSearch] = useState("")

  const term = search.trim().toLowerCase()

  // Pendiente es todo mes que no está saldado: sin pagar, en revisión o
  // rechazado. Sin consumos o confirmado no deben nada.
  const settled = (status: AdminConsumerRow["status"]) =>
    !status || status === "approved"

  const inTab = consumers.filter(
    (consumer) => filter === "all" || !settled(consumer.status),
  )

  const shown = inTab.filter(
    (consumer) =>
      term === "" ||
      consumer.name.toLowerCase().includes(term) ||
      consumer.email.toLowerCase().includes(term),
  )

  function selectMonth(key: string) {
    router.get(
      adminConsumers.index({
        query: {
          ...(key === current_month ? {} : { month: key }),
          ...(filter === "pending" ? { filter } : {}),
        },
      }).url,
      {},
      { preserveScroll: true, preserveState: true },
    )
  }

  const emptyKey = consumers.length === 0 ? "empty" : "no_results"

  const breadcrumbs: BreadcrumbItem[] = [
    { title: t(`${page}.title`), href: adminConsumers.index().url },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t(`${page}.title`)} />

      <PageContainer
        title={t(`${page}.title`)}
        badge={
          <Badge variant="secondary">
            <span aria-hidden="true">{inTab.length}</span>
            <span className="sr-only">
              {t(`${page}.count`, { count: inTab.length })}
            </span>
          </Badge>
        }
        actions={
          <MonthSelect
            value={month}
            currentMonth={current_month}
            months={months}
            onValueChange={selectMonth}
            label={t(`${page}.month_label`)}
          />
        }
      >
        <ToggleGroup
          type="single"
          value={filter}
          // Radix manda "" al destildar la opción activa; el filtro siempre tiene una.
          onValueChange={(value) => value && setFilter(value as Filter)}
          aria-label={t(`${page}.filter_label`)}
          className="bg-muted w-full rounded-lg p-[3px]"
        >
          <ToggleGroupItem value="all" className={segment}>
            {t(`${page}.all`)}
          </ToggleGroupItem>
          <ToggleGroupItem value="pending" className={segment}>
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
