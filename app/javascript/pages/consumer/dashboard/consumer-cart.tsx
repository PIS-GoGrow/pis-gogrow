import { Link } from "@inertiajs/react"
import { type TFunction } from "i18next"
import { ChevronLeft, TriangleAlert } from "lucide-react"
import { useTranslation } from "react-i18next"

import { BottomAction, MobileCard } from "@/components/consumer/mobile-card"
import { QuantityInput } from "@/components/quantity-input"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { Button } from "@/components/ui/button"
import { RadioGroup } from "@/components/ui/radio-group"
import { Spinner } from "@/components/ui/spinner"
import { formatLongDate } from "@/lib/dates"
import { formatMoney } from "@/lib/money"
import { cn } from "@/lib/utils"
import { consumerDashboard } from "@/routes"

import { AddAddressSheet } from "./add-address-sheet"
import { AddressOption } from "./address-option"
import type { CartItem, DeliveryAddressOption } from "./consumer-types"
import { BenefitLine, OrderSummary } from "./order-summary"
import type { DiscountTier, Pricing } from "./pricing"
import { SavedAddressesSheet } from "./saved-addresses-sheet"

interface Props {
  monthlyLimit: number
  monthlyRemaining: number
  pricing: Pricing | null
  cart: CartItem[]
  addresses: DeliveryAddressOption[]
  address: string
  setAddress: (value: string) => void
  onAddAddress: (option: DeliveryAddressOption, saved: boolean) => void
  processing: boolean
  error?: string | string[]
  confirm: () => void
  remove: (cartId: string) => void
  setQuantity: (cartId: string, quantity: number) => void
  loading: boolean
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
  confirm,
  remove,
  setQuantity,
  loading,
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
  const deliveryDates = [...new Set(cart.map((item) => item.date))]
  // Con un solo día de entrega la fecha va arriba; con varios, cada plato
  // lleva la suya.
  const singleDeliveryDate =
    deliveryDates.length === 1 ? deliveryDates[0] : null
  const deliveryLabel = (date: string) =>
    t("pages.cart.delivery", {
      date: formatLongDate(date),
    })

  return (
    <MobileCard>
      <Link href={consumerDashboard.index()}>
        <Button
          type="button"
          variant="ghost"
          size="icon"
          disabled={processing}
          aria-label="Volver"
          className="mb-3"
        >
          <ChevronLeft aria-hidden="true" className="size-5" />
        </Button>
      </Link>
      <h1 className="text-xl font-bold">Tu carrito</h1>
      {singleDeliveryDate && (
        <p className="text-muted-foreground mt-2 text-sm">
          {deliveryLabel(singleDeliveryDate)}
        </p>
      )}
      <section className="border-border mt-8 border-b pb-4">
        <div className="mb-3 flex items-center justify-between text-sm font-semibold">
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

      {(pricing?.fullPriceQuantity ?? 0) > 0 && (
        <Alert className="mt-4 border-amber-300 bg-amber-50 text-amber-900 dark:bg-amber-950/30 dark:text-amber-200">
          <TriangleAlert aria-hidden="true" className="text-amber-600" />
          <AlertDescription>
            <p>{fullPriceNotice(t, monthlyLimit, monthlyRemaining, pricing)}</p>
          </AlertDescription>
        </Alert>
      )}

      <section className="border-border mt-6 pb-4 text-sm md:border-b">
        {cart.map((item, i) => {
          const line = item.menu.price * item.quantity
          return (
            <div
              key={item.cartId}
              className="border-border mb-3 border-b pb-3 last:mb-0 last:border-b-0 last:pb-0"
            >
              {!singleDeliveryDate && (
                <p className="text-muted-foreground mb-2">
                  {deliveryLabel(item.date)}
                </p>
              )}
              <div className="flex justify-between">
                <span className="text-muted-foreground">
                  {item.menu.name} x{item.quantity}
                </span>
                <span>{formatMoney(line)}</span>
              </div>
              {pricing?.lines?.[i] && (
                <ItemBenefitLines tiers={pricing.lines[i].tiers} />
              )}
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
              <div className="mt-2">
                <QuantityInput
                  size="sm"
                  value={item.quantity}
                  max={item.remaining}
                  disabled={processing}
                  onChange={(quantity) => setQuantity(item.cartId, quantity)}
                  onRemove={() => remove(item.cartId)}
                  decreaseLabel={t("pages.cart.decrease", {
                    name: item.menu.name,
                  })}
                  increaseLabel={t("pages.cart.increase", {
                    name: item.menu.name,
                  })}
                  removeLabel={t("pages.cart.remove", { name: item.menu.name })}
                />
              </div>
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
          loading={loading}
          subtotal={pricing?.subtotal}
          total={pricing?.total}
          compact
        />
        <Button
          disabled={
            !cart.length || processing || !selectedAddress || missingOffice
          }
          onClick={confirm}
          className={cn(
            "bg-primary text-primary-foreground hover:bg-primary/90 hover:text-primary-foreground mt-4 h-12 w-full disabled:opacity-100",
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

// Explica por qué parte del pedido va a precio completo. Sin cupo mensual pero
// con un subsidio especial aplicado, no se dice que no hay beneficio.
function fullPriceNotice(
  t: TFunction,
  monthlyLimit: number,
  monthlyRemaining: number,
  pricing: Pricing | null,
) {
  const subsidized = pricing?.subsidizedQuantity ?? 0
  const full = pricing?.fullPriceQuantity ?? 0

  const reason =
    monthlyLimit === 0
      ? subsidized === 0 && t("pages.cart.monthly.no_benefit")
      : monthlyRemaining === 0
        ? t("pages.cart.monthly.used_up", { count: monthlyLimit })
        : t("pages.cart.monthly.remaining", { count: monthlyRemaining })
  const detail =
    subsidized > 0
      ? t("pages.cart.monthly.split", { subsidized, full })
      : t("pages.cart.monthly.full_price", { count: full })

  return [reason, detail].filter(Boolean).join(" ")
}

function ItemBenefitLines({ tiers }: { tiers: DiscountTier[] }) {
  const discounted = tiers.filter((tier) => tier.discount > 0)

  if (discounted.length === 0) return <BenefitLine className="mt-3" />

  return discounted.map((tier, index) => (
    <BenefitLine
      key={`${tier.name ?? "base"}-${tier.percentage}-${index}`}
      tier={tier}
      className="mt-3"
    />
  ))
}
