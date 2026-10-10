import { Head, useForm, usePage } from "@inertiajs/react"
import { useMemo, useState } from "react"

import useSessionStorage from "@/hooks/use-session-storage"
import AppLayout from "@/layouts/app-layout"
import { consumerDashboard, consumerOrders } from "@/routes"
import type { ConsumerDashboardIndex } from "@/types"

import { ConsumerCart } from "./consumer-cart"
import type {
  CartItem,
  DeliveryAddressOption,
  Schedule,
  Selections,
} from "./consumer-types"
import { DishDetail } from "./dish-detail"
import { OrderError } from "./order-error"
import { cartPricedItem, priceItems } from "./pricing"
import { today, WeeklyMenu } from "./weekly-menu"

type View = "menu" | "detail" | "cart" | "confirmation" | "error"

export default function Index({
  week,
  schedules,
  benefit,
  addresses,
}: ConsumerDashboardIndex) {
  const { auth } = usePage().props
  const [view, setView] = useState<View>("menu")
  const todayDate = today()
  const initialDate =
    week.days.find((d) => d.date === todayDate)?.date ??
    week.days[0]?.date ??
    ""
  const [date, setDate] = useState(initialDate)
  const [selected, setSelected] = useState<Schedule | null>(null)
  // Guardamos el carrito en sessionStorage. Así, se persiste si el consumidor
  // recarga la página o navega por la aplicación, pero se borra si cierra la
  // tab del navegador.
  const [cart, setCart] = useSessionStorage<CartItem[]>("cart", [])
  const [quantity, setQuantity] = useState(1)
  const [notes, setNotes] = useState("")
  const [selections, setSelections] = useState<Selections>({})
  const [address, setAddress] = useState(addresses[0]?.address ?? "")
  const [unsavedAddresses, setUnsavedAddresses] = useState<
    DeliveryAddressOption[]
  >([])

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

  const providers = useMemo(
    () => [...new Set(schedules.map((item) => item.menu.provider_name))],
    [schedules],
  )

  const visibleSchedules = schedules.filter((item) => item.date === date)

  const pricing = priceItems(cart.map(cartPricedItem), benefit)

  const count = cart.reduce((sum, item) => sum + item.quantity, 0)
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

  function openDetail(item: Schedule) {
    setSelected(item)
    setQuantity(1)
    setNotes("")
    setSelections({})
    setView("detail")
  }

  function addToCart() {
    if (!selected || selected.sold_out || selected.orders_closed) return

    // Dos veces el mismo plato con distinta personalización son dos líneas del
    // carrito, así que la clave incluye lo elegido además de las notas.
    const cartId = `${selected.id}-${JSON.stringify(selections)}-${notes}`

    setCart((items) => {
      const found = items.find((item) => item.cartId === cartId)

      return found
        ? items.map((item) =>
            item.cartId === cartId
              ? {
                  ...item,
                  quantity: Math.min(item.remaining, item.quantity + quantity),
                }
              : item,
          )
        : [
            ...items,
            {
              ...selected,
              cartId,
              quantity: Math.min(selected.remaining, quantity),
              notes,
              selections,
            },
          ]
    })

    setView("menu")
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
        <Head title="Menú semanal" />
        {view === "menu" && (
          <WeeklyMenu
            name={auth.user.name.split(" ")[0]}
            date={date}
            setDate={setDate}
            benefit={benefit}
            providers={providers}
            schedules={visibleSchedules}
            cart={cart}
            count={count}
            total={pricing.total}
            openDetail={openDetail}
            openCart={() => setView("cart")}
          />
        )}
        {view === "detail" && selected && (
          <DishDetail
            item={selected}
            quantity={quantity}
            setQuantity={setQuantity}
            notes={notes}
            selections={selections}
            setSelections={setSelections}
            setNotes={setNotes}
            benefit={benefit}
            cart={cart}
            back={() => setView("menu")}
            add={addToCart}
          />
        )}
        {view === "cart" && (
          <ConsumerCart
            monthlyLimit={benefit.monthly_limit}
            monthlyRemaining={benefit.monthly_remaining}
            pricing={pricing}
            cart={cart}
            addresses={addressOptions}
            address={address}
            setAddress={setAddress}
            onAddAddress={addAddress}
            processing={form.processing}
            error={form.errors.order_error}
            back={() => setView("menu")}
            confirm={confirm}
            remove={(cartId) => {
              setCart((items) => items.filter((item) => item.cartId !== cartId))
              form.clearErrors()
            }}
          />
        )}
        {view === "error" && (
          <OrderError
            retry={() => {
              form.clearErrors()
              setView("cart")
            }}
            homeUrl={consumerDashboard.index().url}
            error={
              Array.isArray(form.errors.order_error)
                ? form.errors.order_error[0]
                : form.errors.order_error
            }
          />
        )}
      </div>
    </AppLayout>
  )
}
