import { Head, useForm, usePage } from "@inertiajs/react"
import { useMemo, useState } from "react"

import AppLayout from "@/layouts/app-layout"
import { consumerDashboard, orders } from "@/routes"
import type { ConsumerDashboardIndex } from "@/types"

import { ConsumerCart } from "./consumer-cart"
import type { CartItem, Schedule } from "./consumer-types"
import { DishDetail } from "./dish-detail"
import { WeeklyMenu } from "./weekly-menu"

type View = "menu" | "detail" | "cart"

export default function Index({
  week,
  schedules,
  benefit,
  addresses,
}: ConsumerDashboardIndex) {
  const { auth } = usePage().props
  const [view, setView] = useState<View>("menu")
  const [date, setDate] = useState(week.days[0]?.date ?? "")
  const [provider, setProvider] = useState("all")
  const [selected, setSelected] = useState<Schedule | null>(null)
  const [cart, setCart] = useState<CartItem[]>([])
  const [quantity, setQuantity] = useState(1)
  const [notes, setNotes] = useState("")
  const [filling, setFilling] = useState("")
  const [sauce, setSauce] = useState("")
  const [address, setAddress] = useState(addresses[0]?.address ?? "")
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
  const visibleSchedules = schedules.filter(
    (item) =>
      item.date === date &&
      (provider === "all" || item.menu.provider_name === provider),
  )
  const subtotal = cart.reduce(
    (sum, item) => sum + item.menu.price * item.quantity,
    0,
  )
  const discount = (subtotal * benefit.percentage) / 100
  const total = subtotal - discount
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
      const found = items.find((item) => item.id === selected.id)
      return found
        ? items.map((item) =>
            item.id === selected.id
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
    form.post(orders.create().url, {
      onSuccess: () => {
        setCart([])
        setView("menu")
      },
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
      <main className="min-h-svh bg-[#fafafa] text-[#151515] md:min-h-[calc(100svh-4rem)]">
        <Head title="Menú semanal" />
        {view === "menu" && (
          <WeeklyMenu
            name={auth.user.name.split(" ")[0]}
            week={week}
            date={date}
            setDate={setDate}
            benefit={benefit}
            providers={providers}
            provider={provider}
            setProvider={setProvider}
            schedules={visibleSchedules}
            cart={cart}
            count={count}
            total={total}
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
        {view === "cart" && (
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
          />
        )}
      </main>
    </AppLayout>
  )
}
