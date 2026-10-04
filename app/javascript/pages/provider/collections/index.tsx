import { Head } from "@inertiajs/react"
import { SlidersHorizontal, Wallet } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import CollectionGroupCard from "@/components/collections/collection-group-card"
import HeadingSmall from "@/components/heading-small"
import PageContainer from "@/components/page-container"
import Stat from "@/components/stat"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuRadioGroup,
  DropdownMenuRadioItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import {
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyMedia,
  EmptyTitle,
} from "@/components/ui/empty"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { useFormatters } from "@/hooks/use-formatters"
import AppLayout from "@/layouts/app-layout"
import { providerCollections } from "@/routes"
import type {
  BreadcrumbItem,
  ProviderCollectionGroup,
  ProviderCollectionsIndex,
} from "@/types"

type Tab = "pending" | "history"

export default function Index({
  sales,
  outstanding,
  clients,
  pending,
  history,
}: ProviderCollectionsIndex) {
  const { t } = useTranslation()
  const { formatMoney } = useFormatters()
  // "all" o el id del cliente como string, que es lo que maneja el menú.
  const [client, setClient] = useState("all")

  const selectedClient = clients.find((option) => String(option.id) === client)

  const visible = (groups: ProviderCollectionGroup[]) =>
    selectedClient
      ? groups.filter((group) => group.client_id === selectedClient.id)
      : groups

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.provider_collections.index.title"),
      href: providerCollections.index().url,
    },
  ]

  const renderTab = (tab: Tab, groups: ProviderCollectionGroup[]) => {
    const shown = visible(groups)

    if (shown.length === 0) {
      return (
        <Empty className="border">
          <EmptyHeader>
            <EmptyMedia variant="icon">
              <Wallet aria-hidden="true" />
            </EmptyMedia>
            <EmptyTitle>
              {t(`pages.provider_collections.index.empty_${tab}_title`)}
            </EmptyTitle>
            <EmptyDescription>
              {selectedClient
                ? t(`pages.provider_collections.index.empty_${tab}_client`)
                : t(`pages.provider_collections.index.empty_${tab}_all`)}
            </EmptyDescription>
          </EmptyHeader>
        </Empty>
      )
    }

    // items-start: al desplegar una tarjeta, su vecina de fila no se estira.
    return (
      <div className="grid items-start gap-4 lg:grid-cols-2">
        {shown.map((group) => (
          <CollectionGroupCard
            key={group.key}
            group={group}
            settled={tab === "history"}
          />
        ))}
      </div>
    )
  }

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t("pages.provider_collections.index.title")} />

      <PageContainer title={t("pages.provider_collections.index.title")}>
        <div className="grid gap-4 md:grid-cols-2">
          <Stat
            label={t("pages.provider_collections.index.sales")}
            badge={
              <Badge variant="secondary">
                {t("pages.provider_collections.index.this_month")}
              </Badge>
            }
            value={formatMoney(sales.total)}
            detail={`| ${t("pages.provider_collections.index.confirmed_meals", { count: sales.meals })}`}
          />
          <Stat
            label={t("pages.provider_collections.index.outstanding")}
            badge={
              <Badge variant="secondary">
                {t("pages.provider_collections.index.total_debt")}
              </Badge>
            }
            value={formatMoney(outstanding.total)}
            detail={`| ${t("pages.provider_collections.index.delivered_meals", { count: outstanding.meals })}`}
          />
        </div>

        <HeadingSmall title={t("pages.provider_collections.index.section")} />

        <Tabs defaultValue="pending" className="gap-4">
          <TabsList className="w-full">
            <TabsTrigger value="pending">
              {t("pages.provider_collections.index.pending_tab")}
            </TabsTrigger>
            <TabsTrigger value="history">
              {t("pages.provider_collections.index.history_tab")}
            </TabsTrigger>
          </TabsList>

          <div className="flex items-center justify-between gap-2">
            <p className="text-sm">
              {t("pages.provider_collections.index.clients")}{" "}
              <span className="text-muted-foreground">
                {selectedClient?.name ??
                  t("pages.provider_collections.index.all_clients")}
              </span>
            </p>
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button
                  variant="outline"
                  size="icon"
                  className="rounded-full"
                  aria-label={t(
                    "pages.provider_collections.index.filter_clients",
                  )}
                >
                  <SlidersHorizontal aria-hidden="true" />
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end">
                <DropdownMenuRadioGroup
                  value={client}
                  onValueChange={setClient}
                >
                  <DropdownMenuRadioItem value="all">
                    {t("pages.provider_collections.index.all_clients")}
                  </DropdownMenuRadioItem>
                  {clients.map((option) => (
                    <DropdownMenuRadioItem
                      key={option.id}
                      value={String(option.id)}
                    >
                      {option.name}
                    </DropdownMenuRadioItem>
                  ))}
                </DropdownMenuRadioGroup>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>

          <TabsContent value="pending">
            {renderTab("pending", pending)}
          </TabsContent>
          <TabsContent value="history">
            {renderTab("history", history)}
          </TabsContent>
        </Tabs>
      </PageContainer>
    </AppLayout>
  )
}
