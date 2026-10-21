import { useForm } from "@inertiajs/react"
import { Pencil } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import {
  AdaptableDialog,
  AdaptableDialogContent,
  AdaptableDialogDescription,
  AdaptableDialogTitle,
  AdaptableDialogTrigger,
} from "@/components/adaptable-dialog"
import OptionChoices from "@/components/menus/option-choices"
import { QuantityInput } from "@/components/quantity-input"
import { Button } from "@/components/ui/button"
import { Field, FieldLabel } from "@/components/ui/field"
import { RadioGroup } from "@/components/ui/radio-group"
import { Spinner } from "@/components/ui/spinner"
import { Textarea } from "@/components/ui/textarea"
import { AddressOption } from "@/pages/consumer/dashboard/address-option"
import { SavedAddressesSheet } from "@/pages/consumer/dashboard/saved-addresses-sheet"
import { consumerOrders } from "@/routes"
import type { ConsumerOrdersShow, Order } from "@/types"

interface EditOrderSheetProps {
  order: Order
  addresses: ConsumerOrdersShow["delivery_addresses"]
  optionGroups: ConsumerOrdersShow["option_groups"]
  maxQuantity: number
  editing: boolean
}

export default function EditOrderSheet({
  order,
  addresses,
  optionGroups,
  maxQuantity,
  editing,
}: EditOrderSheetProps) {
  const { t } = useTranslation()
  const [open, setOpen] = useState(editing)

  const { data, setData, patch, processing, transform } = useForm({
    quantity: order.amount ?? 1,
    address: order.address ?? addresses[0]?.address ?? "",
    notes: order.notes ?? "",
    options: optionGroups.map((group) => ({
      group_id: group.id,
      values:
        order.selected_options.find((option) => option.group_id === group.id)
          ?.values ?? [],
    })),
  })

  const missingChoice = optionGroups.some(
    (group) =>
      group.required &&
      !data.options.find((option) => option.group_id === group.id)?.values
        .length,
  )

  const office = addresses.find((item) => item.id === "office")
  const customAddresses = addresses.filter((item) => item.id !== "office")
  const visibleAddresses = [
    office,
    customAddresses.find((item) => item.address === data.address) ??
      customAddresses[0],
  ].filter((item) => item !== undefined)

  function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()

    transform((data) => ({ order: data }))

    patch(consumerOrders.update(order.id).url, {
      preserveScroll: true,

      // El servidor puede rechazar el cambio (cupo, plazo) y aun así responder
      // una visita exitosa: el flash de error es lo que distingue los dos casos.
      onSuccess: (page) => {
        if (!page.flash.alert) setOpen(false)
      },
    })
  }

  return (
    <AdaptableDialog
      open={open}
      onOpenChange={(next) => {
        setOpen(next)

        if (!next)
          window.history.replaceState(null, "", window.location.pathname)
      }}
    >
      <AdaptableDialogTrigger asChild>
        <Button type="button" variant="outline" size="sm" className="w-full">
          <Pencil aria-hidden="true" />
          {t("pages.orders.show.edit")}
        </Button>
      </AdaptableDialogTrigger>

      <AdaptableDialogContent
        showCloseButton={false}
        className="max-h-[90dvh] overflow-y-auto p-5"
      >
        <form onSubmit={handleSubmit} className="flex min-w-0 flex-col gap-5">
          <AdaptableDialogTitle className="text-base leading-6 font-semibold tracking-normal">
            {t("pages.orders.show.edit_dialog.title")}
          </AdaptableDialogTitle>

          <AdaptableDialogDescription className="text-base leading-6">
            {t("pages.orders.show.edit_dialog.description")}
          </AdaptableDialogDescription>

          <Field>
            <FieldLabel htmlFor="quantity">
              {t("pages.orders.show.edit_dialog.quantity")}
            </FieldLabel>

            <div className="flex items-center gap-3">
              <QuantityInput
                value={data.quantity}
                max={maxQuantity}
                onChange={(quantity) => setData("quantity", quantity)}
              />

              <input type="hidden" id="quantity" value={data.quantity} />
            </div>
          </Field>

          <Field>
            <FieldLabel>
              {t("pages.orders.show.edit_dialog.address")}
            </FieldLabel>

            <RadioGroup
              value={data.address}
              onValueChange={(address) => setData("address", address)}
              disabled={processing || addresses.length <= 1}
              className="gap-3"
            >
              {visibleAddresses.map((item) => (
                <AddressOption
                  key={item.id}
                  option={item}
                  selected={data.address === item.address}
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
          </Field>

          {optionGroups.map((group) => (
            <OptionChoices
              key={group.id}
              group={group}
              values={
                data.options.find((option) => option.group_id === group.id)
                  ?.values ?? []
              }
              setValues={(values) =>
                setData(
                  "options",
                  data.options.map((option) =>
                    option.group_id === group.id
                      ? { ...option, values }
                      : option,
                  ),
                )
              }
            />
          ))}

          <Field>
            <FieldLabel htmlFor="notes">
              {t("pages.orders.show.edit_dialog.notes")}
            </FieldLabel>

            <Textarea
              id="notes"
              name="notes"
              maxLength={140}
              value={data.notes}
              placeholder={t("pages.orders.show.edit_dialog.notes_placeholder")}
              onChange={(event) => setData("notes", event.target.value)}
              className="field-sizing-fixed h-20 w-full max-w-full min-w-0 resize-none rounded-lg p-3 text-xs"
            />

            <p className="text-muted-foreground text-right text-[10px]">
              {data.notes.length}/140
            </p>
          </Field>

          <div className="grid grid-cols-2 gap-3">
            <Button
              type="button"
              variant="outline"
              className="h-12 rounded-lg text-base font-medium"
              onClick={() => setOpen(false)}
            >
              {t("pages.orders.show.edit_dialog.back")}
            </Button>

            <Button
              type="submit"
              className="h-12 rounded-lg text-base font-medium"
              disabled={processing || missingChoice}
            >
              {processing && <Spinner />}
              {t("pages.orders.show.edit_dialog.confirm")}
            </Button>
          </div>
        </form>
      </AdaptableDialogContent>
    </AdaptableDialog>
  )
}
