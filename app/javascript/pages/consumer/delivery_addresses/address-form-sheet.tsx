import { useForm } from "@inertiajs/react"
import { Trash2 } from "lucide-react"
import type { ReactNode } from "react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import {
  AdaptableDialog,
  AdaptableDialogContent,
  AdaptableDialogDescription,
  AdaptableDialogTitle,
  AdaptableDialogTrigger,
} from "@/components/adaptable-dialog"
import { Button } from "@/components/ui/button"
import { Field, FieldError, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { Spinner } from "@/components/ui/spinner"
import { consumerDeliveryAddresses } from "@/routes"
import type { ConsumerDeliveryAddress } from "@/types"

interface Props {
  address?: ConsumerDeliveryAddress
  children: ReactNode
  onDelete?: (address: ConsumerDeliveryAddress) => void
}

export default function AddressFormSheet({
  address,
  children,
  onDelete,
}: Props) {
  const { t } = useTranslation()
  const [open, setOpen] = useState(false)
  const editing = address != null
  const suffix = address?.id ?? "new"

  const {
    data,
    setData,
    post,
    patch,
    processing,
    errors,
    clearErrors,
    reset,
    transform,
  } = useForm({
    name: address?.name ?? "",
    street: address?.street ?? "",
    apartment: address?.apartment ?? "",
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

    transform((current) => ({
      delivery_address: current,
      source: "addresses",
    }))

    const options = {
      preserveScroll: true,
      onSuccess: () => handleOpenChange(false),
    }

    if (editing) {
      patch(consumerDeliveryAddresses.update(address.id).url, options)
    } else {
      post(consumerDeliveryAddresses.create().url, options)
    }
  }

  return (
    <AdaptableDialog open={open} onOpenChange={handleOpenChange}>
      <AdaptableDialogTrigger asChild>{children}</AdaptableDialogTrigger>

      <AdaptableDialogContent
        showCloseButton={false}
        className="min-h-[455px] gap-0 rounded-t-[26px] border-[#E5E5E5] px-6 pt-2.5 pb-8 md:min-h-0 md:gap-4 md:rounded-lg md:p-6"
      >
        <div
          aria-hidden="true"
          className="mx-auto h-[5px] w-20 rounded-full bg-[#E5E5E5] md:hidden"
        />

        <form
          onSubmit={handleSubmit}
          className="flex flex-col gap-5 pt-6 md:pt-0"
          noValidate
        >
          <div className="flex items-center justify-between gap-5">
            <AdaptableDialogTitle className="text-base leading-6 font-semibold tracking-normal">
              {t(
                editing
                  ? "pages.consumer_delivery_addresses.form.edit_title"
                  : "pages.consumer_delivery_addresses.form.create_title",
              )}
            </AdaptableDialogTitle>

            {editing && onDelete && (
              <Button
                type="button"
                variant="ghost"
                className="h-5 gap-1.5 px-0 py-0 text-sm font-semibold text-red-700 hover:bg-transparent hover:text-red-700"
                onClick={() => {
                  handleOpenChange(false)
                  onDelete(address)
                }}
              >
                <Trash2 aria-hidden="true" className="size-4" />
                {t("pages.consumer_delivery_addresses.form.delete")}
              </Button>
            )}
          </div>

          <AdaptableDialogDescription className="sr-only">
            {t("pages.consumer_delivery_addresses.form.description")}
          </AdaptableDialogDescription>
          
          <div className="grid gap-4">
            <Field data-invalid={!!errors.name} className="gap-3">
              <FieldLabel htmlFor={`delivery_address_name_${suffix}`}>
                {t("pages.consumer_delivery_addresses.form.name")}
              </FieldLabel>

              <Input
                id={`delivery_address_name_${suffix}`}
                value={data.name}
                maxLength={40}
                autoComplete="off"
                placeholder={t(
                  "pages.consumer_delivery_addresses.form.name_placeholder",
                )}
                aria-invalid={!!errors.name}
                onChange={(event) => {
                  setData("name", event.target.value)
                  clearErrors("name")
                }}
                className="h-12 rounded-lg shadow-none"
              />

              <FieldError errors={errors.name?.map((message) => ({ message }))} />
            </Field>

            <Field data-invalid={!!errors.street} className="gap-3">
              <FieldLabel htmlFor={`delivery_address_street_${suffix}`}>
                {t("pages.consumer_delivery_addresses.form.street")}
              </FieldLabel>

              <Input
                id={`delivery_address_street_${suffix}`}
                value={data.street}
                maxLength={120}
                autoComplete="street-address"
                aria-invalid={!!errors.street}
                onChange={(event) => {
                  setData("street", event.target.value)
                  clearErrors("street")
                }}
                className="h-12 rounded-lg shadow-none"
              />

              <FieldError
                errors={errors.street?.map((message) => ({ message }))}
              />
            </Field>

            <Field data-invalid={!!errors.apartment} className="gap-3">
              <FieldLabel htmlFor={`delivery_address_apartment_${suffix}`}>
                {t("pages.consumer_delivery_addresses.form.apartment")}
              </FieldLabel>

              <Input
                id={`delivery_address_apartment_${suffix}`}
                value={data.apartment}
                maxLength={40}
                autoComplete="off"
                aria-invalid={!!errors.apartment}
                onChange={(event) => {
                  setData("apartment", event.target.value)
                  clearErrors("apartment")
                }}
                className="h-12 rounded-lg shadow-none"
              />

              <FieldError
                errors={errors.apartment?.map((message) => ({ message }))}
              />
            </Field>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <Button
              type="button"
              variant="secondary"
              className="h-12 rounded-[10px] text-base font-medium shadow-none"
              onClick={() => handleOpenChange(false)}
            >
              {t("pages.consumer_delivery_addresses.form.cancel")}
            </Button>

            <Button
              type="submit"
              disabled={processing}
              className="h-12 rounded-[10px] text-base font-medium shadow-none"
            >
              {processing && <Spinner />}
              {t(
                editing
                  ? "pages.consumer_delivery_addresses.form.update"
                  : "pages.consumer_delivery_addresses.form.create",
              )}
            </Button>
          </div>
        </form>
      </AdaptableDialogContent>
    </AdaptableDialog>
  )
}
