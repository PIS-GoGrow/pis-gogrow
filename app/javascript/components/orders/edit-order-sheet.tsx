import { router, useForm } from "@inertiajs/react"
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
import StatusBadge from "@/components/status-badge"
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

type Step = "form" | "modify_confirmed" | "add_units" | "cancel" | "modified"

interface ConfirmStepProps {
  title: string
  description: string
  back?: string
  confirm: string
  processing?: boolean
  onBack?: () => void
  onConfirm: () => void
}

function ConfirmStep({
  title,
  description,
  back,
  confirm,
  processing = false,
  onBack,
  onConfirm,
}: ConfirmStepProps) {
  return (
    <div className="flex flex-col gap-5">
      <AdaptableDialogTitle className="text-base leading-6 font-semibold tracking-normal">
        {title}
      </AdaptableDialogTitle>
      <AdaptableDialogDescription className="text-base leading-6">
        {description}
      </AdaptableDialogDescription>

      <div className={back ? "grid grid-cols-2 gap-3" : "grid"}>
        {back && (
          <Button
            type="button"
            variant="outline"
            className="h-12 rounded-lg text-base font-medium"
            disabled={processing}
            onClick={onBack}
          >
            {back}
          </Button>
        )}
        <Button
          type="button"
          className="h-12 rounded-lg text-base font-medium"
          disabled={processing}
          onClick={onConfirm}
        >
          {processing && <Spinner />}
          {confirm}
        </Button>
      </div>
    </div>
  )
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
  const [step, setStep] = useState<Step>("form")
  const [cancelling, setCancelling] = useState(false)
  // Con ?edit=1 se llega desde la lista de pedidos, y al terminar hay que
  // volver ahí y no al detalle. Se guarda al montar porque el redirect del
  // guardado ya no trae el parámetro.
  const [cameFromList] = useState(editing)

  const initial = {
    quantity: order.amount ?? 1,
    address: order.address ?? addresses[0]?.address ?? "",
    notes: order.notes ?? "",
    options: optionGroups.map((group) => ({
      group_id: group.id,
      values:
        order.selected_options.find((option) => option.group_id === group.id)
          ?.values ?? [],
    })),
  }

  const { data, setData, patch, processing, transform } = useForm(initial)

  const missingChoice = optionGroups.some(
    (group) =>
      group.required &&
      !data.options.find((option) => option.group_id === group.id)?.values
        .length,
  )

  const confirmed = order.status === "confirmed"
  const sameDetails =
    JSON.stringify({ ...data, quantity: 0 }) ===
    JSON.stringify({ ...initial, quantity: 0 })
  const unchanged = sameDetails && data.quantity === initial.quantity

  const office = addresses.find((item) => item.id === "office")
  const customAddresses = addresses.filter((item) => item.id !== "office")
  const visibleAddresses = [
    office,
    customAddresses.find((item) => item.address === data.address) ??
      customAddresses[0],
  ].filter((item) => item !== undefined)

  function leave() {
    router.visit(
      cameFromList
        ? consumerOrders.index().url
        : consumerOrders.show(order.id).url,
      { replace: true },
    )
  }

  function handleOpenChange(next: boolean) {
    if (next) {
      setStep("form")
      setOpen(true)
      return
    }

    if (step === "modified" || cameFromList) {
      leave()
      return
    }

    setOpen(false)
    window.history.replaceState(null, "", window.location.pathname)
  }

  function save() {
    transform((data) => ({ order: data }))

    patch(consumerOrders.update(order.id).url, {
      preserveScroll: true,
      // Un pedido confirmado vuelve como otro pedido: sin preservar el estado,
      // la página se monta de nuevo y se pierde el aviso de "Pedido modificado".
      preserveState: true,

      // El servidor puede rechazar el cambio (cupo, plazo) y aun así responder
      // una visita exitosa: el flash de error es lo que distingue los dos casos.
      onSuccess: (page) => {
        const hasAlert =
          (page.props as { flash?: { alert?: string } })?.flash?.alert ??
          page.flash?.alert
        setStep(hasAlert ? "form" : "modified")
      },
    })
  }

  function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()

    if (!confirmed) return save()

    setStep(
      sameDetails && data.quantity > initial.quantity
        ? "add_units"
        : "modify_confirmed",
    )
  }

  function handleCancel() {
    setCancelling(true)

    router.patch(
      consumerOrders.cancel(order.id),
      {},
      {
        preserveScroll: true,
        onFinish: () => setCancelling(false),
      },
    )
  }

  return (
    <AdaptableDialog open={open} onOpenChange={handleOpenChange}>
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
        {step === "modify_confirmed" && (
          <ConfirmStep
            title={t("pages.orders.show.modify_confirmed_dialog.title")}
            description={t(
              "pages.orders.show.modify_confirmed_dialog.description",
            )}
            back={t("pages.orders.show.modify_confirmed_dialog.back")}
            confirm={t("pages.orders.show.modify_confirmed_dialog.confirm")}
            processing={processing}
            onBack={() => setStep("form")}
            onConfirm={save}
          />
        )}

        {step === "add_units" && (
          <ConfirmStep
            title={t("pages.orders.show.add_units_dialog.title")}
            description={t("pages.orders.show.add_units_dialog.description")}
            back={t("pages.orders.show.add_units_dialog.back")}
            confirm={t("pages.orders.show.add_units_dialog.confirm")}
            processing={processing}
            onBack={() => setStep("form")}
            onConfirm={save}
          />
        )}

        {step === "cancel" && (
          <ConfirmStep
            title={t("pages.orders.index.cancel_dialog.title")}
            description={t("pages.orders.index.cancel_dialog.description")}
            back={t("pages.orders.index.cancel_dialog.back")}
            confirm={t("pages.orders.index.cancel_dialog.confirm")}
            processing={cancelling}
            onBack={() => setStep("form")}
            onConfirm={handleCancel}
          />
        )}

        {step === "modified" && (
          <ConfirmStep
            title={t("pages.orders.show.modified_dialog.title")}
            description={t("pages.orders.show.modified_dialog.description")}
            confirm={t("pages.orders.show.modified_dialog.done")}
            onConfirm={leave}
          />
        )}

        {step === "form" && (
          <form onSubmit={handleSubmit} className="flex min-w-0 flex-col gap-5">
            <div className="grid gap-1">
              <div className="flex items-center justify-between gap-3">
                <p className="text-muted-foreground text-sm">
                  {order.provider_name ?? t("pages.orders.index.no_provider")}
                </p>
                <StatusBadge status={order.status} />
              </div>

              <AdaptableDialogTitle className="text-xl leading-7 font-bold tracking-normal">
                {order.menu_name ?? t("pages.orders.index.no_menu")}
              </AdaptableDialogTitle>
            </div>

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
                  onRemove={
                    order.cancellable ? () => setStep("cancel") : undefined
                  }
                  removeLabel={t("pages.orders.show.edit_dialog.remove")}
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
                placeholder={t(
                  "pages.orders.show.edit_dialog.notes_placeholder",
                )}
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
                onClick={() => handleOpenChange(false)}
              >
                {t("pages.orders.show.edit_dialog.back")}
              </Button>

              <Button
                type="submit"
                className="h-12 rounded-lg text-base font-medium"
                disabled={
                  processing || missingChoice || (confirmed && unchanged)
                }
              >
                {processing && <Spinner />}
                {t("pages.orders.show.edit_dialog.confirm")}
              </Button>
            </div>
          </form>
        )}
      </AdaptableDialogContent>
    </AdaptableDialog>
  )
}
