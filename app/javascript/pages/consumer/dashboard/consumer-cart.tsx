import { ChevronLeft, MapPin, TriangleAlert } from "lucide-react"
import { useTranslation } from "react-i18next"

import { Alert, AlertDescription } from "@/components/ui/alert"
import { Button } from "@/components/ui/button"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { Spinner } from "@/components/ui/spinner"
import { cn } from "@/lib/utils"
import type { ConsumerDashboardIndex } from "@/types"

import type { CartItem } from "./consumer-types"
import { money } from "./formatters"
import { OrderSummary } from "./order-summary"

interface Props {
  cart: CartItem[]
  addresses: ConsumerDashboardIndex["addresses"]
  address: string
  setAddress: (value: string) => void
  percentage: number
  subtotal: number
  discount: number
  total: number
  processing: boolean
  error?: string | string[]
  back: () => void
  confirm: () => void
  remove: (cartId: string) => void
}

export function ConsumerCart({
  cart,
  addresses,
  address,
  setAddress,
  percentage,
  subtotal,
  discount,
  total,
  processing,
  error,
  back,
  confirm,
  remove,
}: Props) {
  const { t } = useTranslation()
  const office = addresses.find((item) => item.id === "office")
  const officeOnlyProviders = [
    ...new Set(
      cart
        .filter((item) => !item.menu.home_delivery)
        .map((item) => item.menu.provider_name),
    ),
  ]
  const missingOffice = officeOnlyProviders.length > 0 && !office
  const showDeliveryWarning =
    officeOnlyProviders.length > 0 && !!address && address !== office?.address

  return (
    <div className="mx-auto min-h-screen max-w-3xl bg-white px-6 pt-6 pb-8 md:my-8 md:min-h-0 md:rounded-2xl md:border md:border-[#e5e5e5] md:p-8">
      <Button
        type="button"
        variant="ghost"
        size="icon"
        onClick={back}
        disabled={processing}
        aria-label="Volver"
        className="mb-3"
      >
        <ChevronLeft aria-hidden="true" className="size-5" />
      </Button>
      <h1 className="text-xl font-bold">Tu carrito</h1>
      <section className="mt-8 border-b border-[#e5e5e5] pb-4">
        <div className="mb-3 flex justify-between text-xs font-semibold">
          <h2>Dirección de entrega</h2>
          <Button
            type="button"
            variant="ghost"
            size="sm"
            aria-disabled="true"
            className="text-xs text-[#171717]"
          >
            ＋ Agregar
          </Button>
        </div>
        <RadioGroup
          value={address}
          onValueChange={setAddress}
          disabled={processing}
          className="gap-3"
        >
          {addresses.map((item) => (
            <label
              key={item.id}
              className={cn(
                "flex min-h-[66px] gap-3 rounded-lg border border-[#e5e5e5] bg-white p-3",
                address === item.address && "border-black bg-[#f5f5f5]",
              )}
            >
              <RadioGroupItem
                value={item.address}
                className="mt-0.5 border-[#737373] bg-white text-black shadow-none data-[state=checked]:border-black data-[state=checked]:bg-white dark:bg-white dark:data-[state=checked]:bg-white [&_svg]:fill-black [&_svg]:text-black"
              />
              <span className="text-xs">
                <b>{item.label}</b>
                <small className="mt-1 block text-[#888]">{item.address}</small>
              </span>
            </label>
          ))}
        </RadioGroup>
        <Button
          type="button"
          variant="ghost"
          size="sm"
          aria-disabled="true"
          className="mt-3 px-0 text-xs font-semibold text-[#171717]"
        >
          <MapPin aria-hidden="true" className="size-4" />
          Ver mis direcciones
        </Button>
        {showDeliveryWarning && (
          <Alert className="mt-3 border-0 bg-transparent p-0 text-amber-700">
            <TriangleAlert aria-hidden="true" className="text-amber-500" />
            <AlertDescription className="gap-1 text-amber-700">
              {missingOffice ? (
                <p>{t("pages.cart.office_address_missing")}</p>
              ) : (
                <>
                  {officeOnlyProviders.map((provider) => (
                    <p key={provider}>
                      {t("pages.cart.office_delivery_warning", { provider })}
                    </p>
                  ))}
                  {cart.some((item) => item.menu.home_delivery) && (
                    <p>{t("pages.cart.other_deliveries")}</p>
                  )}
                </>
              )}
            </AlertDescription>
          </Alert>
        )}
      </section>
      <section className="mt-6 border-b border-[#e5e5e5] pb-4 text-xs">
        {cart.map((item) => {
          const line = item.menu.price * item.quantity
          return (
            <div key={item.cartId} className="mb-3 last:mb-0">
              <p className="mb-2 text-[#777]">
                {t("pages.cart.delivery", {
                  date: new Date(`${item.date}T12:00:00`).toLocaleDateString(
                    "es-UY",
                    {
                      weekday: "long",
                      day: "numeric",
                      month: "long",
                    },
                  ),
                })}
              </p>
              <div className="flex justify-between text-[#777]">
                <span>
                  {item.menu.name} x{item.quantity}
                </span>
                <span>{money(line)}</span>
              </div>
              {item.notes && <p className="mt-2 text-[#777]">{item.notes}</p>}
              <Button
                type="button"
                variant="ghost"
                size="sm"
                disabled={processing}
                onClick={() => remove(item.cartId)}
                className="mt-2"
              >
                {t("pages.cart.remove", { name: item.menu.name })}
              </Button>
              <div className="mt-2 flex justify-between text-[#29944c]">
                <span>Beneficio GoGrow ({percentage}%)</span>
                <span>- {money((line * percentage) / 100)}</span>
              </div>
            </div>
          )
        })}
        {!cart.length && (
          <p className="py-6 text-center text-[#888]">
            Todavía no agregaste platos.
          </p>
        )}
      </section>
      <OrderSummary
        subtotal={subtotal}
        discount={discount}
        total={total}
        percentage={percentage}
        compact
      />
      <Button
        disabled={!cart.length || processing || !address || missingOffice}
        onClick={confirm}
        className={cn(
          "mt-4 h-12 w-full bg-black text-white hover:bg-black/85 hover:text-white disabled:opacity-100",
          processing && "bg-[#999] hover:bg-[#999]",
        )}
      >
        {processing ? (
          <>
            <Spinner />
            Confirmando pedido
          </>
        ) : (
          "Confirmar pedido"
        )}
      </Button>
      {error && (
        <Alert variant="destructive" className="mt-3">
          <AlertDescription>
            {Array.isArray(error) ? error.join(" ") : error}
          </AlertDescription>
        </Alert>
      )}
    </div>
  )
}
