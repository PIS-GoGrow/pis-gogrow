import { ChevronLeft, TriangleAlert } from "lucide-react"
import { useTranslation } from "react-i18next"
import { useForm, Link } from "@inertiajs/react"
import { useState, useEffect } from "react"

import AppLayout from "@/layouts/app-layout"
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
import { SavedAddressesSheet } from "./saved-addresses-sheet"

import useSessionStorage from "@/hooks/use-session-storage"

import { consumerOrders, dashboard, consumerDashboard } from "@/routes"

import type { ConsumerDashboardCart } from "@/types"

import { Pricing, cartPricedItem, priceItems } from "./pricing"
import { OrderError } from "./order-error"

type View = "error" | "cart"

export default function ConsumerCart({
  benefit,
  addresses,
}: ConsumerDashboardCart) {
  const [cart, setCart] = useSessionStorage<CartItem[]>("cart", [])
  const [address, setAddress] = useState(addresses[0]?.address ?? "")
  const [view, setView] = useState<View>("cart")

  const form = useForm({
    address: "",
    order_error: "",
    items: [] as {
      schedule_id: number
      quantity: number
      notes: string
      options: { group_id: number; values: string[] }[]
    }[],
  })

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
  const customDisabled = form.processing || !homeDeliveryAvailable
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

  const [unsavedAddresses, setUnsavedAddresses] = useState<
    DeliveryAddressOption[]
  >([])

  const addressOptions = [
    ...addresses,
    ...unsavedAddresses.filter(
      (unsaved) => !addresses.some((item) => item.address === unsaved.address),
    ),
  ]

  function addAddress(option: DeliveryAddressOption, saved: boolean) {
    if (!saved) {
      setUnsavedAddresses((items) => [
        option,
        ...items.filter((item) => item.address !== option.address),
      ])
    }
    setAddress(option.address)
  }

  function remove(cartId: string) {
    setCart((items) => items.filter((item) => item.cartId !== cartId))
    form.clearErrors()
  }

  function confirm() {
    if (!cart.length || form.processing || !address) return

    const items = cart.map((item) => ({
      schedule_id: item.id,
      quantity: item.quantity,
      notes: item.notes,
      options: Object.entries(item.selections).map(([groupId, values]) => ({
        group_id: Number(groupId),
        values,
      })),
    }))

    form.transform(() => ({ order: { address, items } }))

    form.post(consumerOrders.create().url, {
      preserveState: true,
      preserveScroll: false,
      onSuccess: () => setCart([]),
        onError: () => setView("error"),
    })
  }

  const [loading, setLoading] = useState<boolean>(true)
  const [pricing, setPricing] = useState<Pricing | null>(null)

  useEffect(() => {
    // No consultar con el carrito vacío (incluye el primer render, antes de cargar el storage)
    if (cart.length === 0) {
      setPricing(null)
      setLoading(false)
      return
    }

    const handlePrice = async () => {
      setLoading(true)
      const result = await priceItems(cart.map(cartPricedItem))

      setPricing(result)
      setLoading(false)
    }

    handlePrice()
  }, [cart])

  return (
  <AppLayout
    breadcrumbs={[{ title: "Menú", href: consumerDashboard.index().url }]}
  >
    <style>
      {
        '@media (max-width: 767px) { [data-slot="sidebar-inset"] > header { display: none; } }'
      }
    </style>
    <div className="bg-background text-foreground min-h-svh md:min-h-[calc(100svh-4rem)]">
    {view === "cart" ? (
    <MobileCard>

      <Link href={dashboard().url}>
      <Button
        type="button"
        variant="ghost"
        size="icon"
        disabled={form.processing}
        aria-label="Volver"
        className="mb-3"
      >
        <ChevronLeft aria-hidden="true" className="size-5" />
        </Button>
      </Link>
      <h1 className="text-xl font-bold">Tu carrito</h1>
      <section className="border-border mt-8 border-b pb-4">
        <div className="mb-3 flex items-center justify-between text-sm font-semibold">
          <h2>{t("pages.cart.delivery_address")}</h2>
          <AddAddressSheet disabled={customDisabled} onAdd={addAddress} />
        </div>
        <RadioGroup
          value={selectedAddress}
          onValueChange={setAddress}
          disabled={form.processing}
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

      {(pricing?.fullPriceQuantity || 0) > 0 && (
        <Alert className="mt-4 border-amber-300 bg-amber-50 text-amber-900 dark:bg-amber-950/30 dark:text-amber-200">
          <TriangleAlert aria-hidden="true" className="text-amber-600" />
          <AlertDescription>
            {benefit.monthly_remaining === 0 ? (
              <p>
                Ya utilizaste las {benefit.monthly_limit} viandas subsidiadas de este
                mes. Las {pricing?.fullPriceQuantity} viandas de este pedido se
                cobrarán a precio completo.
              </p>
            ) : (
              <p>
                Te quedan {benefit.monthly_remaining} viandas subsidiadas este mes. De
                este pedido, {pricing?.subsidizedQuantity} tendrán el beneficio y{" "}
                {pricing?.fullPriceQuantity} se cobrarán a precio completo.
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
              {pricing?.lines[item.id]?.tiers
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
                disabled={form.processing}
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
          loading={loading}
          subtotal={pricing?.subtotal}
          total={pricing?.total}
          compact
        />
        <Button
          disabled={
            !cart.length || form.processing || !selectedAddress || missingOffice
          }
          onClick={confirm}
          className={cn(
            "bg-primary text-primary-foreground hover:bg-primary/90 hover:text-primary-foreground mt-4 h-12 w-full disabled:opacity-100",
            form.processing && "bg-muted hover:bg-muted",
          )}
        >
          {form.processing ? (
            <>
              <Spinner />
              Confirmando pedido
            </>
          ) : (
            "Confirmar pedido"
          )}
        </Button>
      </BottomAction>
      {form.errors.order_error && (
        <Alert variant="destructive" className="mt-3">
          <AlertDescription>
            {Array.isArray(form.errors.order_error) ? form.errors.order_error.join(" ") : form.errors.order_error}
          </AlertDescription>
        </Alert>
      )}
    </MobileCard>
        ) : (
            <OrderError retry={() => {
                          form.clearErrors()
                          setView("cart")
                        }}
                        error={
                          Array.isArray(form.errors.order_error)
                            ? form.errors.order_error[0]
                            : form.errors.order_error
                        } />
    )}
    </div>
  </AppLayout>
  )
}
