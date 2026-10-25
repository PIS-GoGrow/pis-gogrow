import { Head, router, useForm } from "@inertiajs/react"
import { useTranslation } from "react-i18next"

import { RadioGroup } from "@/components/ui/radio-group"
import AppLayout from "@/layouts/app-layout"
import { AddressOption } from "@/pages/consumer/dashboard/address-option"
import { DishDetail } from "@/pages/consumer/dashboard/dish-detail"
import { SavedAddressesSheet } from "@/pages/consumer/dashboard/saved-addresses-sheet"
import { consumerOrders } from "@/routes"
import type { BreadcrumbItem, ConsumerOrdersEdit } from "@/types"

export default function Edit({
  order,
  schedule,
  delivery_addresses,
}: ConsumerOrdersEdit) {
  const { t } = useTranslation()

  const { data, setData, patch, processing, transform } = useForm({
    quantity: order.amount ?? 1,
    address: order.address ?? delivery_addresses[0]?.address ?? "",
    notes: order.notes ?? "",
    selections: Object.fromEntries(
      order.selected_options.map((option) => [option.group_id, option.values]),
    ),
  })

  const office = delivery_addresses.find((item) => item.id === "office")
  const customAddresses = delivery_addresses.filter(
    (item) => item.id !== "office",
  )
  const visibleAddresses = [
    office,
    customAddresses.find((item) => item.address === data.address) ??
      customAddresses[0],
  ].filter((item) => item !== undefined)

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
          orderId={order.id}
          actionLabel={t("pages.orders.edit.save")}
          processing={processing}
        >
          <section className="border-border border-b py-4">
            <h2 className="text-xs font-semibold">
              {t("pages.orders.edit.address")}
            </h2>
            <RadioGroup
              value={data.address}
              onValueChange={(address) => setData("address", address)}
              disabled={processing || delivery_addresses.length <= 1}
              className="mt-3 gap-3"
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
                addresses={delivery_addresses}
                address={data.address}
                disabled={processing}
                onSelect={(address) => setData("address", address)}
              />
            )}
          </section>
        </DishDetail>
      </div>
    </AppLayout>
  )
}
