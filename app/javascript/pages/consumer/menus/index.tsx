import { router, usePage } from "@inertiajs/react"
import { Head } from "@inertiajs/react"
import { SlidersHorizontal, UtensilsCrossed } from "lucide-react"
import { useState } from "react"

import MenuItem from "@/components/consumer/menus/menu-item"
import WeekNav from "@/components/consumer/menus/week-nav"
import { Button } from "@/components/ui/button"
import { Checkbox } from "@/components/ui/checkbox"
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import {
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyMedia,
  EmptyTitle,
} from "@/components/ui/empty"
import { Label } from "@/components/ui/label"
import AppLayout from "@/layouts/app-layout"
import { consumerMenus } from "@/routes"
import type { BreadcrumbItem, ConsumerMenusIndex, SharedProps } from "@/types"

function formatDateHeading(dateStr: string): string {
  const d = new Date(dateStr + "T00:00:00")
  const str = d.toLocaleDateString("es-AR", {
    weekday: "long",
    day: "numeric",
    month: "long",
  })
  return str.charAt(0).toUpperCase() + str.slice(1)
}

function todayStr(): string {
  const d = new Date()
  return [
    d.getFullYear(),
    String(d.getMonth() + 1).padStart(2, "0"),
    String(d.getDate()).padStart(2, "0"),
  ].join("-")
}

export default function Index({
  date,
  schedules,
  providers,
}: ConsumerMenusIndex) {
  const { auth } = usePage<SharedProps>().props
  const firstName = auth.user.name.split(" ")[0]
  const isPast = date < todayStr()

  const [filterOpen, setFilterOpen] = useState(false)
  const [pendingProviders, setPendingProviders] = useState<Set<number>>(
    new Set(),
  )
  const [activeProviders, setActiveProviders] = useState<Set<number>>(new Set())

  function handleFilterOpen() {
    setPendingProviders(new Set(activeProviders))
    setFilterOpen(true)
  }

  function handleFilterApply() {
    setActiveProviders(new Set(pendingProviders))
    setFilterOpen(false)
  }

  function toggleProvider(id: number) {
    setPendingProviders((prev) => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return next
    })
  }

  const filteredSchedules =
    activeProviders.size === 0
      ? schedules
      : schedules.filter((s) => activeProviders.has(s.menu.provider.id))

  function handleDateChange(newDate: string) {
    router.get(
      consumerMenus.index().url,
      { date: newDate },
      { preserveScroll: true },
    )
  }

  const filterLabel =
    activeProviders.size === 0
      ? "Todos"
      : providers
          .filter((p) => activeProviders.has(p.id))
          .map((p) => p.name)
          .join(", ")

  const breadcrumbs: BreadcrumbItem[] = [
    { title: "Menú del día", href: consumerMenus.index().url },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title="Menú del día" />

      <div className="mx-auto w-full max-w-300 p-5">
        <div className="mb-6">
          <h1 className="text-2xl font-bold">Hola, {firstName} 👋</h1>
          <p className="text-muted-foreground text-sm">
            {formatDateHeading(date)}
          </p>
        </div>

        <WeekNav date={date} onChange={handleDateChange} />

        <div className="mt-6 mb-3 flex items-center">
          <span className="text-muted-foreground text-sm">
            Proveedores:{" "}
            <span className="text-foreground font-medium">{filterLabel}</span>
          </span>
          <Button
            variant="ghost"
            size="icon"
            className="ml-auto size-7"
            onClick={handleFilterOpen}
          >
            <SlidersHorizontal className="size-4" />
          </Button>
        </div>

        {filteredSchedules.length === 0 ? (
          <Empty className="mt-8">
            <EmptyHeader>
              <EmptyMedia variant="icon">
                <UtensilsCrossed />
              </EmptyMedia>
              <EmptyTitle>Menú no disponible</EmptyTitle>
              <EmptyDescription>
                {schedules.length === 0
                  ? "Todavía no hay viandas publicadas para este día. Volvé a consultar más tarde."
                  : "No hay platos de los proveedores seleccionados para esta fecha. Probá cambiando el filtro."}
              </EmptyDescription>
            </EmptyHeader>
          </Empty>
        ) : (
          <div>
            {filteredSchedules.map((schedule) => (
              <MenuItem
                key={schedule.id}
                providerName={schedule.menu.provider.name}
                name={schedule.menu.name ?? "Plato sin nombre"}
                price={schedule.menu.price ?? 0}
                description={schedule.menu.description}
                soldOut={schedule.amount === 0}
                isPast={isPast}
              />
            ))}
          </div>
        )}
      </div>

      <Dialog open={filterOpen} onOpenChange={setFilterOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Filtrar por Proveedores</DialogTitle>
          </DialogHeader>
          <div className="flex flex-col gap-3 py-2">
            <div className="flex items-center gap-2">
              <Checkbox
                id="filter-all"
                checked={pendingProviders.size === 0}
                onCheckedChange={() => setPendingProviders(new Set())}
              />
              <Label htmlFor="filter-all">Todos</Label>
            </div>
            {providers.map((p) => (
              <div key={p.id} className="flex items-center gap-2">
                <Checkbox
                  id={`filter-p-${p.id}`}
                  checked={pendingProviders.has(p.id)}
                  onCheckedChange={() => toggleProvider(p.id)}
                />
                <Label htmlFor={`filter-p-${p.id}`}>{p.name}</Label>
              </div>
            ))}
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setFilterOpen(false)}>
              Cancelar
            </Button>
            <Button onClick={handleFilterApply}>Aplicar</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </AppLayout>
  )
}
