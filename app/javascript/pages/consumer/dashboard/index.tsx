import { Head, usePage } from "@inertiajs/react"
import { useEffect, useMemo, useState } from "react"

import { useConsumerMenuFilter } from "@/hooks/consumer-menu-filter"
import useSessionStorage from "@/hooks/use-session-storage"
import AppLayout from "@/layouts/app-layout"
import { consumerDashboard } from "@/routes"
import type { ConsumerDashboardIndex } from "@/types"

import type { CartItem, Schedule, Selections } from "./consumer-types"
import { DishDetail } from "./dish-detail"
import type { Pricing } from "./pricing"
import { cartPricedItem, priceItems } from "./pricing"
import { WeeklyMenu, today } from "./weekly-menu"

type View = "menu" | "detail"

export default function Index({
  week,
  schedules,
  providers,
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
  const { activeProviders, setActiveProviders } = useConsumerMenuFilter()
  const [selected, setSelected] = useState<Schedule | null>(null)
  // Guardamos el carrito en sessionStorage. Así, se persiste si el consumidor
  // recarga la página o navega por la aplicación, pero se borra si cierra la
  // tab del navegador.
  const [cart, setCart] = useSessionStorage<CartItem[]>("cart", [])
  const [quantity, setQuantity] = useState(1)
  const [notes, setNotes] = useState("")
  const [selections, setSelections] = useState<Selections>({})
  const [editingCartId, setEditingCartId] = useState<string | null>(null)

  const visibleSchedules = schedules.filter((item) => item.date === date)

  const count = cart.reduce((sum, item) => sum + item.quantity, 0)

  function openDetail(item: Schedule) {
    setSelected(item)
    const existing = cart.find((c) => c.id === item.id)
    if (existing) {
      setEditingCartId(existing.cartId)
      setQuantity(existing.quantity)
      setNotes(existing.notes)
      setSelections(existing.selections)
    } else {
      setEditingCartId(null)
      setQuantity(1)
      setNotes("")
      setSelections({})
    }
    setView("detail")
  }

  function handleBack() {
    setEditingCartId(null)
    setView("menu")
  }

  function handleRemoveFromCartAndBack() {
    if (!editingCartId) return
    setCart((items) => items.filter((item) => item.cartId !== editingCartId))
    setEditingCartId(null)
    setView("menu")
  }

  function addToCart(benefitsSelected: number[]) {
    if (!selected || selected.sold_out || selected.orders_closed) return

    // Dos veces el mismo plato con distinta personalización son dos líneas del
    // carrito, así que la clave incluye lo elegido además de las notas.
    const cartId = `${selected.id}-${JSON.stringify(selections)}-${notes}-${JSON.stringify(benefitsSelected)}`

    setCart((items) => {
      if (editingCartId) {
        const targetIndex = items.findIndex(
          (item) => item.cartId === editingCartId,
        )
        if (targetIndex === -1) return items

        const withoutCurrent = items.filter(
          (item) => item.cartId !== editingCartId,
        )
        const duplicate = withoutCurrent.find((item) => item.cartId === cartId)
        if (duplicate) {
          return withoutCurrent.map((item) =>
            item.cartId === cartId
              ? {
                  ...item,
                  quantity: Math.min(item.remaining, item.quantity + quantity),
                }
              : item,
          )
        }

        const updatedItem: CartItem = {
          ...selected,
          cartId,
          quantity: Math.min(selected.remaining, quantity),
          notes,
          selections,
          benefits: benefitsSelected,
        }

        const next = [...items]
        next[targetIndex] = updatedItem
        return next
      }

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
              benefits: benefitsSelected,
            },
          ]
    })

    setEditingCartId(null)
    setView("menu")
  }

  const items = useMemo(() => cartPricedItem(cart), [cart])
  const requestKey = useMemo(() => JSON.stringify(items), [items])

  // Guarda el resultado junto con el carrito para el que se calculó
  const [priced, setPriced] = useState<{
    key: string
    pricing: Pricing | null
  } | null>(null)

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
        <Head title="Menú semanal" />
        {view === "menu" && (
          <WeeklyMenu
            name={auth.user.name.split(" ")[0]}
            date={date}
            setDate={setDate}
            benefit={benefit}
            providers={providers}
            activeProviders={activeProviders}
            setActiveProviders={setActiveProviders}
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
            back={handleBack}
            add={addToCart}
            editingCartId={editingCartId}
            onRemove={editingCartId ? handleRemoveFromCartAndBack : undefined}
            benefit={benefit}
          />
        )}
      </div>
    </AppLayout>
  )
}
