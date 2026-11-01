import { useForm } from "@inertiajs/react"
import { useEffect, useMemo, useState } from "react"

import useSessionStorage from "@/hooks/use-session-storage"
import AppLayout from "@/layouts/app-layout"
import { consumerDashboard, consumerOrders } from "@/routes"
import type { ConsumerDashboardCart } from "@/types"

import { ConsumerCart } from "./consumer-cart"
import type { CartItem, DeliveryAddressOption } from "./consumer-types"
import { OrderError } from "./order-error"
import type { Pricing } from "./pricing"
import { cartPricedItem, priceItems } from "./pricing"

// Es un formulario que redirige a ConsumerCart o a OrderError según si el formulario
// tiene o no errores.
export default function Cart({ benefit, addresses }: ConsumerDashboardCart) {
  const [unsavedAddresses, setUnsavedAddresses] = useState<
    DeliveryAddressOption[]
  >([])
  const [selectedAddress, setSelectedAddress] = useState<string | null>(null)

  const addressOptions = [
    ...addresses,
    ...unsavedAddresses.filter(
      (unsaved) => !addresses.some((item) => item.address === unsaved.address),
    ),
  ]

  const address =
    addressOptions.find((o) => o.address === selectedAddress)?.address ??
    addressOptions[0]?.address ??
    ""

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
  const [cart, setCart] = useSessionStorage<CartItem[]>("cart", [])

  function addAddress(option: DeliveryAddressOption, saved: boolean) {
    if (!saved) {
      setUnsavedAddresses((items) => [
        option,
        ...items.filter((item) => item.address !== option.address),
      ])
    }
    setSelectedAddress(option.address)
  }

  function remove(cartId: string) {
    setCart((items) => items.filter((item) => item.cartId !== cartId))
    form.clearErrors()
  }

  function setQuantity(cartId: string, quantity: number) {
    setCart((items) =>
      items.map((item) =>
        item.cartId === cartId
          ? {
              ...item,
              quantity: Math.min(item.remaining, Math.max(1, quantity)),
            }
          : item,
      ),
    )
    form.clearErrors()
  }

  function confirm() {
    if (!cart.length || form.processing || !address) return

    const items = cart.map((item) => ({
      schedule_id: item.id,
      quantity: item.quantity,
      benefits: item.benefits,
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
    })
  }

  const items = useMemo(() => cartPricedItem(cart), [cart])
  const requestKey = useMemo(() => JSON.stringify(items), [items])

  // Guarda el resultado junto con el carrito para el que se calculó
  const [priced, setPriced] = useState<{
    key: string
    pricing: Pricing | null
  } | null>(null)

  // Cargamos los precios de los ítems del carrito desde el backend
  useEffect(() => {
    if (items.length === 0) return

    let cancelled = false

    priceItems(items)
      .then((pricing) => {
        if (!cancelled) setPriced({ key: requestKey, pricing })
      })
      .catch(() => {
        // Si falla, marcamos este carrito como resuelto, sin precio, para que loading no quede en true
        if (!cancelled) setPriced({ key: requestKey, pricing: null })
      })

    return () => {
      cancelled = true
    }
  }, [items, requestKey])

  const isEmpty = items.length === 0
  const loading = !isEmpty && priced?.key !== requestKey
  const pricing = isEmpty ? null : (priced?.pricing ?? null)

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
        {form.hasErrors ? (
          <OrderError
            retry={() => {
              form.clearErrors()
            }}
            error={
              Array.isArray(form.errors.order_error)
                ? form.errors.order_error[0]
                : form.errors.order_error
            }
          />
        ) : (
          <ConsumerCart
            monthlyLimit={benefit.monthly_limit}
            monthlyRemaining={benefit.monthly_remaining}
            pricing={pricing}
            loading={loading}
            cart={cart}
            addresses={addressOptions}
            address={address}
            setAddress={(value: string) => setSelectedAddress(value)}
            onAddAddress={addAddress}
            processing={form.processing}
            error={form.errors.order_error}
            confirm={confirm}
            remove={remove}
            setQuantity={setQuantity}
          />
        )}
      </div>
    </AppLayout>
  )
}
