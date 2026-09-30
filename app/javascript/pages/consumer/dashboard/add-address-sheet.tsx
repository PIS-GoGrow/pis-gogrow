import { useForm } from "@inertiajs/react"
import { Plus } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import { Button } from "@/components/ui/button"
import { Checkbox } from "@/components/ui/checkbox"
import { Field, FieldError, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet"
import { Spinner } from "@/components/ui/spinner"
import { consumerDeliveryAddresses } from "@/routes"

import type { DeliveryAddressOption } from "./consumer-types"
import { fullAddress, squish } from "./formatters"

interface Props {
  disabled?: boolean
  onAdd: (option: DeliveryAddressOption, saved: boolean) => void
}

export function AddAddressSheet({ disabled = false, onAdd }: Props) {
  const { t } = useTranslation()
  const [open, setOpen] = useState(false)
  const {
    data,
    setData,
    post,
    processing,
    errors,
    clearErrors,
    reset,
    transform,
  } = useForm({
    name: "",
    street: "",
    apartment: "",
    save_for_later: false,
  })

  function handleOpenChange(nextOpen: boolean) {
    setOpen(nextOpen)
    if (!nextOpen) {
      reset()
      clearErrors()
    }
  }

  function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()

    transform((current) => ({ delivery_address: current }))
    post(consumerDeliveryAddresses.create().url, {
      preserveState: true,
      preserveScroll: true,
      onSuccess: () => {
        onAdd(
          {
            id: `new-${Date.now()}`,
            label: squish(data.name),
            address: fullAddress(data.street, data.apartment),
          },
          data.save_for_later,
        )
        handleOpenChange(false)
      },
    })
  }

  return (
    <Sheet open={open} onOpenChange={handleOpenChange}>
      <SheetTrigger asChild>
        <Button
          type="button"
          variant="ghost"
          size="sm"
          disabled={disabled}
          className="text-foreground h-auto gap-1 px-0 text-sm font-medium hover:bg-transparent"
        >
          <Plus aria-hidden="true" className="size-4" />
          {t("pages.cart.add_address")}
        </Button>
      </SheetTrigger>

      <SheetContent
        side="bottom"
        showCloseButton={false}
        className="border-border bg-background text-foreground gap-6 rounded-t-[32px] border px-6 pt-2.5 pb-8 shadow-none md:inset-x-1/2 md:bottom-1/2 md:w-[402px] md:translate-x-[-50%] md:translate-y-1/2 md:rounded-[32px]"
      >
        <div
          aria-hidden="true"
          className="bg-muted-foreground/30 mx-auto h-1 w-12 rounded-full"
        />

        <form
          onSubmit={handleSubmit}
          className="flex flex-col gap-5"
          noValidate
        >
          <SheetTitle className="text-base leading-6 font-semibold tracking-normal">
            {t("pages.cart.new_address.title")}
          </SheetTitle>
          <SheetDescription className="sr-only">
            {t("pages.cart.new_address.description")}
          </SheetDescription>

          <Field data-invalid={!!errors.name} className="gap-2">
            <FieldLabel htmlFor="delivery_address_name">
              {t("pages.cart.new_address.name")}
            </FieldLabel>
            <Input
              id="delivery_address_name"
              name="name"
              value={data.name}
              maxLength={40}
              autoComplete="off"
              placeholder={t("pages.cart.new_address.name_placeholder")}
              aria-invalid={!!errors.name}
              onChange={(event) => {
                setData("name", event.target.value)
                clearErrors("name")
              }}
              className="h-11 rounded-lg shadow-none"
            />
            <FieldError errors={errors.name?.map((message) => ({ message }))} />
          </Field>

          <Field data-invalid={!!errors.street} className="gap-2">
            <FieldLabel htmlFor="delivery_address_street">
              {t("pages.cart.new_address.street")}
            </FieldLabel>
            <Input
              id="delivery_address_street"
              name="street"
              value={data.street}
              maxLength={120}
              autoComplete="street-address"
              aria-invalid={!!errors.street}
              onChange={(event) => {
                setData("street", event.target.value)
                clearErrors("street")
              }}
              className="h-11 rounded-lg shadow-none"
            />
            <FieldError
              errors={errors.street?.map((message) => ({ message }))}
            />
          </Field>

          <Field data-invalid={!!errors.apartment} className="gap-2">
            <FieldLabel htmlFor="delivery_address_apartment">
              {t("pages.cart.new_address.apartment")}
            </FieldLabel>
            <Input
              id="delivery_address_apartment"
              name="apartment"
              value={data.apartment}
              maxLength={40}
              autoComplete="off"
              aria-invalid={!!errors.apartment}
              onChange={(event) => {
                setData("apartment", event.target.value)
                clearErrors("apartment")
              }}
              className="h-11 rounded-lg shadow-none"
            />
            <FieldError
              errors={errors.apartment?.map((message) => ({ message }))}
            />
          </Field>

          <div className="flex items-center gap-3">
            <Checkbox
              id="delivery_address_save_for_later"
              checked={data.save_for_later}
              onCheckedChange={(checked) =>
                setData("save_for_later", checked === true)
              }
              className="size-4 rounded-full shadow-none"
            />
            <Label
              htmlFor="delivery_address_save_for_later"
              className="cursor-pointer text-sm font-normal"
            >
              {t("pages.cart.new_address.save_for_later")}
            </Label>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <Button
              type="button"
              variant="secondary"
              className="bg-secondary text-secondary-foreground hover:bg-secondary/80 hover:text-secondary-foreground h-12 rounded-lg text-base font-medium shadow-none"
              onClick={() => handleOpenChange(false)}
            >
              {t("pages.cart.new_address.cancel")}
            </Button>
            <Button
              type="submit"
              disabled={processing}
              className="bg-primary text-primary-foreground hover:bg-primary/90 h-12 rounded-lg text-base font-medium shadow-none"
            >
              {processing && <Spinner />}
              {t("pages.cart.new_address.submit")}
            </Button>
          </div>
        </form>
      </SheetContent>
    </Sheet>
  )
}
