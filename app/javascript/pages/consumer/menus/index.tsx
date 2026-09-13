import { Head } from "@inertiajs/react"
import { Utensils } from "lucide-react"
import { useTranslation } from "react-i18next"

import Heading from "@/components/heading"
import AvailableMenuCard from "@/components/menus/available-menu-card"
import {
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyMedia,
  EmptyTitle,
} from "@/components/ui/empty"
import AppLayout from "@/layouts/app-layout"
import { consumerMenus } from "@/routes"
import type { BreadcrumbItem, ConsumerMenusIndex } from "@/types"

export default function Index({ menus }: ConsumerMenusIndex) {
  const { t } = useTranslation()

  const breadcrumbs: BreadcrumbItem[] = [
    { title: t("nav.menus"), href: consumerMenus.index().url },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t("pages.consumer.menus.title")} />

      <div className="mx-auto w-full max-w-300 p-5">
        <Heading
          title={t("pages.consumer.menus.title")}
          description={t("pages.consumer.menus.description")}
        />

        {menus.length === 0 ? (
          <Empty>
            <EmptyHeader>
              <EmptyMedia variant="icon">
                <Utensils aria-hidden="true" />
              </EmptyMedia>
              <EmptyTitle>{t("pages.consumer.menus.empty_title")}</EmptyTitle>
              <EmptyDescription>
                {t("pages.consumer.menus.empty_description")}
              </EmptyDescription>
            </EmptyHeader>
          </Empty>
        ) : (
          <div className="grid gap-4 md:grid-cols-2">
            {menus.map((menu) => (
              <AvailableMenuCard key={menu.id} menu={menu} showLink />
            ))}
          </div>
        )}
      </div>
    </AppLayout>
  )
}
