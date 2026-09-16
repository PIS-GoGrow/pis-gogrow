import { Head, useForm, usePage } from "@inertiajs/react"
import { useMemo, useState } from "react"

import AppLayout from "@/layouts/app-layout"
import { consumerDashboard, consumerOrders } from "@/routes"
import type { ConsumerDashboardIndex } from "@/types"

import { ConsumerCart } from "./consumer-cart"
import type { CartItem, Schedule } from "./consumer-types"
import { DishDetail } from "./dish-detail"
import { OrderConfirmation } from "./order-confirmation"
import { OrderError } from "./order-error"
import { WeeklyMenu } from "./weekly-menu"

type View = "menu" | "detail" | "cart" | "confirmation" | "error"
type Confirmation = NonNullable<ConsumerDashboardIndex["order_confirmation"]>

const totalFor = (items: CartItem[], percentage: number) => {
  const subtotal = items.reduce(
    (sum, item) => sum + item.menu.price * item.quantity,
    0,
  )
  return subtotal - (subtotal * percentage) / 100
}

export default function Index({
  week,
  schedules,
  benefit,
  addresses,
  order_confirmation,
}: ConsumerDashboardIndex) {
  const { auth } = usePage().props
  const [view, setView] = useState<View>("menu")
  const [date, setDate] = useState(week.days[0]?.date ?? "")
  const [selected, setSelected] = useState<Schedule | null>(null)
  const [cart, setCart] = useState<CartItem[]>([])
  const [quantity, setQuantity] = useState(1)
  const [notes, setNotes] = useState("")
  const [filling, setFilling] = useState("")
  const [sauce, setSauce] = useState("")
  const [address, setAddress] = useState(addresses[0]?.address ?? "")
  const [confirmedOrder, setConfirmedOrder] = useState<Confirmation | null>(null)
  const form = useForm({
    address: "",
    order_error: "",
    items: [] as {
      schedule_id: number
      quantity: number
      notes: string
    }[],
  })
  const providers = useMemo(
    () => [...new Set(schedules.map((item) => item.menu.provider_name))],
    [schedules],
  )
  const visibleSchedules = schedules.filter((item) => item.date === date)
  const subtotal = cart.reduce(
    (sum, item) => sum + item.menu.price * item.quantity,
    0,
  )
  const discount = (subtotal * benefit.percentage) / 100
  const total = totalFor(cart, benefit.percentage)
  const count = cart.reduce((sum, item) => sum + item.quantity, 0)

  function openDetail(item: Schedule) {
    setSelected(item)
    setQuantity(1)
    setNotes("")
    setFilling("")
    setSauce("")
    setView("detail")
  }

  function addToCart() {
    if (!selected) return

    const detail = [filling, sauce, notes].filter(Boolean).join(" · ")
    setCart((items) => {
      const found = items.find(
        (item) => item.id === selected.id && item.notes === detail,
      )
      return found
        ? items.map((item) =>
            item.id === selected.id && item.notes === detail
              ? {
                  ...item,
                  quantity: Math.min(item.remaining, item.quantity + quantity),
                  notes: detail,
                }
              : item,
          )
        : [
            ...items,
            {
              ...selected,
              cartId: `${selected.id}-${detail}`,
              quantity: Math.min(selected.remaining, quantity),
              notes: detail,
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
    }))
    form.transform(() => ({ order: { address, items } }))
    form.post(consumerOrders.create().url, {
      preserveState: true,
      preserveScroll: false,
      onSuccess: (page) => {
        const confirmation = (
          page.props as { order_confirmation?: Confirmation }
        ).order_confirmation
        if (!confirmation) return

        setConfirmedOrder(confirmation)
        setCart([])
        setView("confirmation")
      },
      onError: () => setView("error"),
    })
  }

  const activeConfirmation = confirmedOrder ?? order_confirmation
  const activeView = activeConfirmation ? "confirmation" : view

  return (
    <AppLayout
      breadcrumbs={[{ title: "Menú", href: consumerDashboard.index().url }]}
    >
      <style>
        {
          '@media (max-width: 767px) { [data-slot="sidebar-inset"] > header { display: none; } }'
        }
      </style>
      <main className="min-h-svh bg-[#fafafa] text-[#151515] md:min-h-[calc(100svh-4rem)]">
        <Head title="Menú semanal" />
        {activeView === "menu" && (
          <WeeklyMenu
            name={auth.user.name.split(" ")[0]}
            date={date}
            setDate={setDate}
            benefit={benefit}
            providers={providers}
            schedules={visibleSchedules}
            cart={cart}
            count={count}
            total={total}
            openDetail={openDetail}
            openCart={() => setView("cart")}
          />
        )}
        {activeView === "detail" && selected && (
          <DishDetail
            item={selected}
            quantity={quantity}
            setQuantity={setQuantity}
            notes={notes}
            setNotes={setNotes}
            filling={filling}
            setFilling={setFilling}
            sauce={sauce}
            setSauce={setSauce}
            percentage={benefit.percentage}
            back={() => setView("menu")}
            add={addToCart}
          />
        )}
        {activeView === "cart" && (
          <ConsumerCart
            cart={cart}
            addresses={addresses}
            address={address}
            setAddress={setAddress}
            percentage={benefit.percentage}
            subtotal={subtotal}
            discount={discount}
            total={total}
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
        {activeView === "confirmation" && activeConfirmation && (
          <OrderConfirmation
            confirmation={activeConfirmation}
            homeUrl={consumerDashboard.index().url}
          />
        )}
        {activeView === "error" && (
          <OrderError
            retry={() => {
              form.clearErrors()
              setView("cart")
            }}
            homeUrl={consumerDashboard.index().url}
          />
        )}
      </main>
    </AppLayout>
  )
}
