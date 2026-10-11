import { ChevronLeft, TriangleAlert } from "lucide-react"
import { useTranslation } from "react-i18next"

import { BottomAction, MobileCard } from "@/components/consumer/mobile-card"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { Button } from "@/components/ui/button"
import { RadioGroup } from "@/components/ui/radio-group"
import { Spinner } from "@/components/ui/spinner"
import { cn } from "@/lib/utils"

import { AddAddressSheet } from "./add-address-sheet"
import { AddressOption } from "./address-option"
import type { CartItem, DeliveryAddressOption } from "./consumer-types"
import { money } from "./formatters"
import { BenefitLine, OrderSummary } from "./order-summary"
import type { Pricing } from "./pricing"
import { SavedAddressesSheet } from "./saved-addresses-sheet"

interface Props {
  monthlyLimit: number
  monthlyRemaining: number
  pricing: Pricing
  cart: CartItem[]
  addresses: DeliveryAddressOption[]
  address: string
  setAddress: (value: string) => void
  onAddAddress: (option: DeliveryAddressOption, saved: boolean) => void
  processing: boolean
  error?: string | string[]
  back: () => void
  confirm: () => void
  remove: (cartId: string) => void
}

export function ConsumerCart({
  monthlyLimit,
  monthlyRemaining,
  pricing,
  cart,
  addresses,
  address,
  setAddress,
  onAddAddress,
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
  // Sin ningún proveedor que entregue a domicilio, todo el pedido va a la oficina.
  const homeDeliveryAvailable = cart.some((item) => item.menu.home_delivery)
  const customDisabled = processing || !homeDeliveryAvailable
  const selectedAddress =
    homeDeliveryAvailable || !office ? address : office.address
  const customAddresses = addresses.filter((item) => item.id !== "office")
  const visibleAddresses = [
    office,
    customAddresses.find((item) => item.address === selectedAddress) ??
      customAddresses[0],
  ].filter((item) => item !== undefined)
  const showDeliveryWarning =
    officeOnlyProviders.length > 0 &&
    !!selectedAddress &&
    selectedAddress !== office?.address

  return (
    <MobileCard>
      <Button
        type="button"
        variant="ghost"
        size="icon"
        onClick={back}
        disabled={processing}
        aria-label="Volver"
        className="mb-3 size-9 rounded-[10px]"
      >
        <ChevronLeft aria-hidden="true" className="size-4" />
      </Button>
      <h1 className="text-2xl font-bold">Tu carrito</h1>
      <section className="border-border mt-8 border-b pb-4">
        <div className="mb-3 flex items-center justify-between text-base font-semibold">
          <h2>{t("pages.cart.delivery_address")}</h2>
          <AddAddressSheet disabled={customDisabled} onAdd={onAddAddress} />
        </div>
        <RadioGroup
          value={selectedAddress}
          onValueChange={setAddress}
          disabled={processing}
          className="gap-3"
        >
          {visibleAddresses.map((item) => (
            <AddressOption
              key={item.id}
              option={item}
              selected={selectedAddress === item.address}
              disabled={item.id !== "office" && customDisabled}
            />
          ))}
        </RadioGroup>
        <SavedAddressesSheet
          addresses={addresses}
          address={selectedAddress}
          disabled={customDisabled}
          onSelect={setAddress}
        />
        {showDeliveryWarning && (
          <Alert className="mt-3 border-0 bg-transparent p-0 text-amber-700">
            <TriangleAlert aria-hidden="true" className="text-amber-500" />
            <AlertDescription className="gap-1 text-amber-700">
              {missingOffice ? (
                <p>{t("pages.cart.office_address_missing")}</p>
              ) : (
                <p>
                  {t("pages.cart.office_delivery_warning", {
                    count: officeOnlyProviders.length,
                    providers: new Intl.ListFormat("es", {
                      type: "conjunction",
                    }).format(officeOnlyProviders),
                  })}
                </p>
              )}
            </AlertDescription>
          </Alert>
        )}
      </section>

      {pricing.fullPriceQuantity > 0 && (
        <Alert className="mt-4 border-amber-300 bg-amber-50 text-amber-900 dark:bg-amber-950/30 dark:text-amber-200">
          <TriangleAlert aria-hidden="true" className="text-amber-600" />
          <AlertDescription>
            {monthlyRemaining === 0 ? (
              <p>
                Ya utilizaste las {monthlyLimit} viandas subsidiadas de este
                mes. Las {pricing.fullPriceQuantity} viandas de este pedido se
                cobrarán a precio completo.
              </p>
            ) : (
              <p>
                Te quedan {monthlyRemaining} viandas subsidiadas este mes. De
                este pedido, {pricing.subsidizedQuantity} tendrán el beneficio y{" "}
                {pricing.fullPriceQuantity} se cobrarán a precio completo.
              </p>
            )}
          </AlertDescription>
        </Alert>
      )}

      <section className="border-border mt-6 pb-4 text-sm md:border-b">
        {cart.map((item) => {
          const line = item.menu.price * item.quantity
          return (
            <div
              key={item.cartId}
              className="border-border mb-3 border-b pb-3 last:mb-0 last:border-b-0 last:pb-0"
            >
              <p className="text-muted-foreground mb-2">
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
              <div className="flex justify-between">
                <span className="text-muted-foreground">
                  {item.menu.name} x{item.quantity}
                </span>
                <span>{money(line)}</span>
              </div>
              {pricing.lines[item.cartId]?.tiers
                .filter((tier) => tier.discount > 0)
                .map((tier, index) => (
                  <BenefitLine
                    key={`${tier.name ?? "base"}-${tier.percentage}-${index}`}
                    tier={tier}
                    className="mt-3"
                  />
                ))}
              {/* Antes lo elegido viajaba dentro de las notas; ahora es un dato
                  aparte, así que el carrito lo muestra por su cuenta. */}
              {item.menu.option_groups
                .filter((group) => item.selections[group.id]?.length)
                .map((group) => (
                  <p key={group.id} className="text-muted-foreground mt-2">
                    {group.name}: {item.selections[group.id].join(", ")}
                  </p>
                ))}
              {item.notes && (
                <p className="text-muted-foreground mt-2">{item.notes}</p>
              )}
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
            </div>
          )
        })}
        {!cart.length && (
          <p className="text-muted-foreground py-6 text-center">
            Todavía no agregaste platos.
          </p>
        )}
      </section>
      <BottomAction>
        <OrderSummary
          subtotal={pricing.subtotal}
          total={pricing.total}
          compact
        />
        <Button
          disabled={
            !cart.length || processing || !selectedAddress || missingOffice
          }
          onClick={confirm}
          className={cn(
            "bg-primary text-primary-foreground hover:bg-primary/90 hover:text-primary-foreground mt-4 h-12 w-full rounded-[10px] text-base font-medium disabled:opacity-50",
            processing && "bg-muted hover:bg-muted",
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
      </BottomAction>
      {error && (
        <Alert variant="destructive" className="mt-3">
          <AlertDescription>
            {Array.isArray(error) ? error.join(" ") : error}
          </AlertDescription>
        </Alert>
      )}
    </MobileCard>
  )
}
