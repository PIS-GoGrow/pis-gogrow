import { Head, router, useForm } from "@inertiajs/react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import { CancelOrderDialog } from "@/components/orders/cancel-order-sheet"
import OrderUpdatedSheet from "@/components/orders/order-updated-sheet"
import StatusBadge from "@/components/status-badge"
import { RadioGroup } from "@/components/ui/radio-group"
import AppLayout from "@/layouts/app-layout"
import { AddAddressSheet } from "@/pages/consumer/dashboard/add-address-sheet"
import { AddressOption } from "@/pages/consumer/dashboard/address-option"
import type { DeliveryAddressOption } from "@/pages/consumer/dashboard/consumer-types"
import { DishDetail } from "@/pages/consumer/dashboard/dish-detail"
import { SavedAddressesSheet } from "@/pages/consumer/dashboard/saved-addresses-sheet"
import { consumerOrders } from "@/routes"
import type { BreadcrumbItem, ConsumerOrdersEdit } from "@/types"

// El pedido conserva los cupones que ya tiene: al modificarlo no se eligen otros.
const NO_SELECTABLE_BENEFITS = {
  percentage: 0,
  monthly_limit: 0,
  monthly_used: 0,
  monthly_remaining: 0,
  specials: [],
}

export default function Edit({
  order,
  schedule,
  delivery_addresses,
  benefit_ids,
}: ConsumerOrdersEdit) {
  const { t } = useTranslation()
  const [cancelOpen, setCancelOpen] = useState(false)
  const [addedAddresses, setAddedAddresses] = useState<DeliveryAddressOption[]>(
    [],
  )

  const { data, setData, patch, processing, transform } = useForm({
    quantity: order.amount ?? 1,
    address: order.address ?? delivery_addresses[0]?.address ?? "",
    notes: order.notes ?? "",
    selections: Object.fromEntries(
      order.selected_options.map((option) => [option.group_id, option.values]),
    ),
  })

  const addresses = [
    ...delivery_addresses,
    ...addedAddresses.filter(
      (added) =>
        !delivery_addresses.some((item) => item.address === added.address),
    ),
  ]
  const office = addresses.find((item) => item.id === "office")
  const customAddresses = addresses.filter((item) => item.id !== "office")
  const visibleAddresses = [
    office,
    customAddresses.find((item) => item.address === data.address) ??
      customAddresses[0],
  ].filter((item) => item !== undefined)
  const homeDelivery = schedule.menu.home_delivery

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.orders.index.title"),
      href: consumerOrders.index().url,
    },
    {
      title: t("pages.orders.show.title"),
      href: consumerOrders.show(order.id).url,
    },
    {
      title: t("pages.orders.edit.title"),
      href: consumerOrders.edit(order.id).url,
    },
  ]

  function addAddress(option: DeliveryAddressOption) {
    setAddedAddresses((items) => [
      option,
      ...items.filter((item) => item.address !== option.address),
    ])
    setData("address", option.address)
  }

  function save() {
    transform(({ selections, ...rest }) => ({
      order: {
        ...rest,
        options: Object.entries(selections).map(([group_id, values]) => ({
          group_id: Number(group_id),
          values,
        })),
      },
    }))

    patch(consumerOrders.update(order.id).url)
  }

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <style>
        {
          '@media (max-width: 767px) { [data-slot="sidebar-inset"] > header { display: none; } }'
        }
      </style>
      <div className="bg-background text-foreground min-h-svh md:min-h-[calc(100svh-4rem)]">
        <Head title={t("pages.orders.edit.title")} />
        <DishDetail
          item={schedule}
          quantity={data.quantity}
          setQuantity={(quantity) => setData("quantity", quantity)}
          notes={data.notes}
          setNotes={(notes) => setData("notes", notes)}
          selections={data.selections}
          setSelections={(selections) => setData("selections", selections)}
          cart={[]}
          back={() => router.visit(consumerOrders.show(order.id).url)}
          add={save}
          onRemove={() => setCancelOpen(true)}
          orderId={order.id}
          benefit={NO_SELECTABLE_BENEFITS}
          fixedBenefitIds={benefit_ids}
          badge={<StatusBadge status={order.status} />}
          processing={processing}
        >
          <section className="border-border border-b py-4">
            <div className="mb-3 flex items-center justify-between text-sm font-semibold">
              <h2>{t("pages.orders.edit.address")}</h2>
              <AddAddressSheet
                disabled={processing || !homeDelivery}
                onAdd={addAddress}
              />
            </div>
            <RadioGroup
              value={data.address}
              onValueChange={(address) => setData("address", address)}
              disabled={processing || addresses.length <= 1}
              className="gap-3"
            >
              {visibleAddresses.map((option) => (
                <AddressOption
                  key={option.id}
                  option={option}
                  selected={data.address === option.address}
                />
              ))}
            </RadioGroup>
            {customAddresses.length > 1 && (
              <SavedAddressesSheet
                addresses={addresses}
                address={data.address}
                disabled={processing}
                onSelect={(address) => setData("address", address)}
              />
            )}
          </section>
        </DishDetail>

        <CancelOrderDialog
          order={order}
          open={cancelOpen}
          onOpenChange={setCancelOpen}
        />
        <OrderUpdatedSheet />
      </div>
    </AppLayout>
  )
}
