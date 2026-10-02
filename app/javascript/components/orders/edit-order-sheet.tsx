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
import { QuantityInput } from "@/components/quantity-input"
import { Button } from "@/components/ui/button"
import { Field, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { Spinner } from "@/components/ui/spinner"
import { cn } from "@/lib/utils"
import { consumerOrders } from "@/routes"
import type { ConsumerOrdersShow, Order } from "@/types"

interface EditOrderSheetProps {
  order: Order
  addresses: ConsumerOrdersShow["delivery_addresses"]
  maxQuantity: number
  editing: boolean
}

export default function EditOrderSheet({
  order,
  addresses,
  maxQuantity,
  editing,
}: EditOrderSheetProps) {
  const { t } = useTranslation()
  const [open, setOpen] = useState(editing)
  const { data, setData, patch, processing, transform } = useForm({
    quantity: order.amount ?? 1,
    address: order.address ?? addresses[0]?.address ?? "",
    notes: order.notes ?? "",
  })

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

      <AdaptableDialogContent showCloseButton={false} className="p-5">
        <form onSubmit={handleSubmit} className="flex flex-col gap-5">
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
              <p className="text-muted-foreground text-xs">
                {t("pages.orders.show.edit_dialog.remaining", {
                  count: maxQuantity,
                })}
              </p>
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
              {addresses.map((item) => (
                <label
                  key={item.id}
                  className={cn(
                    "border-border bg-card flex min-h-16 gap-3 rounded-lg border p-3",
                    data.address === item.address && "border-primary bg-muted",
                  )}
                >
                  <RadioGroupItem value={item.address} className="mt-0.5" />
                  <span className="text-xs">
                    <b>{item.label}</b>
                    <small className="text-muted-foreground mt-1 block">
                      {item.address}
                    </small>
                  </span>
                </label>
              ))}
            </RadioGroup>
          </Field>

          <Field>
            <FieldLabel htmlFor="notes">
              {t("pages.orders.show.edit_dialog.notes")}
            </FieldLabel>
            <Input
              id="notes"
              name="notes"
              value={data.notes}
              placeholder={t("pages.orders.show.edit_dialog.notes_placeholder")}
              onChange={(event) => setData("notes", event.target.value)}
            />
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
              disabled={processing}
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
