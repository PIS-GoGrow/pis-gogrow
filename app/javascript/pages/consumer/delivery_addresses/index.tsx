import { Head } from "@inertiajs/react"
import { MoreVertical } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import AppLayout from "@/layouts/app-layout"
import SettingsPageLayout from "@/layouts/settings/page-layout"
import { consumerDeliveryAddresses, consumerProfiles } from "@/routes"
import type {
  BreadcrumbItem,
  ConsumerDeliveryAddress,
  ConsumerDeliveryAddressesIndex,
} from "@/types"

import AddressFormSheet from "./address-form-sheet"
import DeleteAddressDialog from "./delete-address-dialog"

export default function Index({
  office_address,
  delivery_addresses,
}: ConsumerDeliveryAddressesIndex) {
  const { t } = useTranslation()
  const page = "pages.consumer_delivery_addresses.index"
  const [deletingAddress, setDeletingAddress] =
    useState<ConsumerDeliveryAddress | null>(null)
  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.consumer_profiles.show.title"),
      href: consumerProfiles.show().url,
    },
    {
      title: t(`${page}.title`),
      href: consumerDeliveryAddresses.index().url,
    },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t(`${page}.title`)} />

      <SettingsPageLayout
        title={t(`${page}.title`)}
        description={t(`${page}.description`)}
        titleVariant="prominent"
        consumerMobileBackHref={consumerProfiles.show().url}
        consumerMobileBackLabel={t(`${page}.back`)}
      >
        <div className="grid w-full gap-3 pb-36 md:pb-0">
          {office_address && (
            <Card className="h-[66px] gap-0 rounded-[10px] py-0 shadow-none">
              <CardContent className="flex h-full items-center justify-between gap-3 px-3 py-0">
                <div className="min-w-0">
                  <p className="truncate text-sm leading-5 font-medium">
                    {t(`${page}.office`)}
                  </p>
                  <p className="text-muted-foreground truncate text-xs leading-4">
                    {office_address}
                  </p>
                </div>
              </CardContent>
            </Card>
          )}

          {delivery_addresses.map((address) => (
            <Card
              key={address.id}
              className="h-[66px] gap-0 rounded-[10px] py-0 shadow-none"
            >
              <CardContent className="flex h-full items-center justify-between gap-3 px-3 py-0">
                <div className="min-w-0">
                  <p className="truncate text-sm leading-5 font-medium">
                    {address.name}
                  </p>
                  <p className="text-muted-foreground truncate text-xs leading-4">
                    {address.address}
                  </p>
                </div>

                <AddressFormSheet
                  key={`${address.id}-${address.name}-${address.address}`}
                  address={address}
                  onDelete={setDeletingAddress}
                >
                  <Button
                    type="button"
                    variant="ghost"
                    size="icon"
                    className="size-10 shrink-0 rounded-[10px]"
                    aria-label={t(`${page}.edit`, {
                      name: address.name,
                    })}
                  >
                    <MoreVertical aria-hidden="true" className="size-4" />
                  </Button>
                </AddressFormSheet>
              </CardContent>
            </Card>
          ))}
        </div>

        <div className="fixed bottom-[88px] left-1/2 z-20 w-[354px] max-w-[calc(100vw-2rem)] -translate-x-1/2 md:static md:w-full md:translate-x-0 md:mt-2">
          <AddressFormSheet>
            <Button
              type="button"
              className="h-12 w-full rounded-[10px] bg-[#171717] text-base font-medium text-[#FAFAFA] hover:bg-[#171717]/90"
            >
              {t(`${page}.add`)}
            </Button>
          </AddressFormSheet>
        </div>
      </SettingsPageLayout>

      <DeleteAddressDialog
        address={deletingAddress}
        open={deletingAddress != null}
        onOpenChange={(open) => {
          if (!open) setDeletingAddress(null)
        }}
      />
    </AppLayout>
  )
}
