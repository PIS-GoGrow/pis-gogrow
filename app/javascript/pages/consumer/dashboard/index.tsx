import { Head, usePage } from "@inertiajs/react"
import { useMemo, useState, useEffect } from "react"

import useSessionStorage from "@/hooks/use-session-storage"
import AppLayout from "@/layouts/app-layout"
import { consumerDashboard } from "@/routes"
import type { ConsumerDashboardIndex } from "@/types"

import type { CartItem, Schedule, Selections } from "./consumer-types"
import { DishDetail } from "./dish-detail"
import { WeeklyMenu, today } from "./weekly-menu"

import { Pricing, cartPricedItem, priceItems } from "./pricing"

type View = "menu" | "detail"

export default function Index({
  week,
  schedules,
  closures,
  benefit,
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

  // Un proveedor cerrado no tiene platos que mostrar, pero tiene que seguir en
  // el filtro para poder ver por qué no hay menú.
  const providers = useMemo(
    () => [
      ...new Set([
        ...schedules.map((item) => item.menu.provider_name),
        ...closures.map((closure) => closure.provider_name),
      ]),
    ],
    [schedules, closures],
  )

  const visibleSchedules = schedules.filter((item) => item.date === date)

  const count = cart.reduce((sum, item) => sum + item.quantity, 0)

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

  const [loading, setLoading] = useState<boolean>(true)
  const [pricing, setPricing] = useState<Pricing | null>(null)

  useEffect(() => {
    // No consultar con el carrito vacío (incluye el primer render, antes de cargar el storage)
    if (cart.length === 0) {
      setPricing(null)
      setLoading(false)
      return
    }

    let cancelled = false
    setLoading(true)

    // Debounce: si el usuario toca "+" varias veces seguidas, solo sale la última consulta
    const timeout = setTimeout(async () => {
      try {
        const result = await priceItems(cart.map(cartPricedItem))
        if (!cancelled) setPricing(result)
      } finally {
        if (!cancelled) setLoading(false)
      }
    }, 250)

    return () => {
      cancelled = true
      clearTimeout(timeout)
    }
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
        <Head title="Menú semanal" />
        {view === "menu" && (
          <WeeklyMenu
            name={auth.user.name.split(" ")[0]}
            date={date}
            setDate={setDate}
            benefit={benefit}
            providers={providers}
            schedules={visibleSchedules}
            closures={closures}
            cart={cart}
            count={count}
            loading={loading}
            total={pricing?.total}
            openDetail={openDetail}
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
            cart={cart}
            back={() => setView("menu")}
            add={addToCart}
          />
        )}
      </div>
    </AppLayout>
  )
}
