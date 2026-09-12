import { Head, router } from "@inertiajs/react"
import { useState } from "react"

import MenuSelectionList from "@/components/schedules/menu-selection-list"
import PublishBar from "@/components/schedules/publish-bar"
import PublishedDayView from "@/components/schedules/published-date-view"
import WeekDayTabs from "@/components/schedules/week-day-tabs"
import AppLayout from "@/layouts/app-layout"
import { schedules as schedulesRoutes } from "@/routes"
import type { BreadcrumbItem, SchedulesIndex } from "@/types"

type SchedulesIndexProps = SchedulesIndex
type ScheduleDay = SchedulesIndex["days"][number]

function formatDateLabel(isoDate: string) {
  const date = new Date(`${isoDate}T00:00:00`)
  const formatted = new Intl.DateTimeFormat("es-UY", {
    weekday: "long",
    day: "numeric",
    month: "long",
  }).format(date)
  return formatted.charAt(0).toUpperCase() + formatted.slice(1)
}

export default function Index({ week, menus, days }: SchedulesIndexProps) {
  const [selectedDate, setSelectedDate] = useState<string | undefined>(
    days.find((day) => day.publishable)?.date ?? days[0]?.date,
  )
  const [selections, setSelections] = useState<
    Record<string, Record<number, string>>
  >({})
  const [processing, setProcessing] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const selectedDay = days.find((day) => day.date === selectedDate)
  const currentSelection = selections[selectedDate ?? ""] ?? {}

  const breadcrumbs: BreadcrumbItem[] = [
    { title: "Publicar menú", href: schedulesRoutes.index().url },
  ]

  function toggleMenu(menuId: number) {
    if (!selectedDate) return

    setSelections((prev) => {
      const daySelection = { ...(prev[selectedDate] ?? {}) }
      if (menuId in daySelection) delete daySelection[menuId]
      else daySelection[menuId] = ""
      return { ...prev, [selectedDate]: daySelection }
    })
  }

  function changeAmount(menuId: number, value: string) {
    if (!selectedDate) return

    setSelections((prev) => ({
      ...prev,
      [selectedDate]: { ...(prev[selectedDate] ?? {}), [menuId]: value },
    }))
  }

  function handlePublish() {
    if (!selectedDate) return

    const items = Object.entries(currentSelection)
      .filter(([, amount]) => amount !== "")
      .map(([menuId, amount]) => ({
        menu_id: Number(menuId),
        amount: Number(amount),
      }))

    // Validaciones del punto 14 del documento: mejoran la UX, pero nunca
    // sustituyen las validaciones que Rails vuelve a hacer del lado del servidor.
    if (items.length === 0) {
      setError("No seleccionaste ningún plato.")
      return
    }
    if (items.some((item) => item.amount <= 0)) {
      setError("El stock debe ser mayor que cero.")
      return
    }

    setProcessing(true)
    setError(null)

    router.post(
      schedulesRoutes.create().url,
      { date: selectedDate, items },
      {
        onError: (errors) => {
          // La selección se conserva a propósito (punto 12): no tocamos
          // `selections` acá, así el proveedor no pierde lo que armó.
          setError(Object.values(errors)[0] ?? "No se pudo publicar el menú.")
        },
        onFinish: () => setProcessing(false),
      },
    )
  }

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title="Publicar menú" />

      <div className="mx-auto flex w-full max-w-300 flex-col gap-4 p-5">
        <div>
          <p className="text-xs font-medium tracking-wide text-muted-foreground uppercase">
            Publicación de menús
          </p>
          <h1 className="text-2xl font-bold">Publicar menú del día</h1>
        </div>

        <WeekDayTabs
          days={days}
          selectedDate={selectedDate}
          onSelectDate={setSelectedDate}
          previousWeekStart={week.previous_week_start}
          nextWeekStart={week.next_week_start}
        />

        {selectedDay && (
          <PublishBar
            dateLabel={formatDateLabel(selectedDay.date)}
            statusLabel={
              selectedDay.published
                ? "Publicado"
                : selectedDay.publishable
                  ? "Sin publicar"
                  : "Fuera de rango de publicación"
            }
            canPublish={selectedDay.publishable && !selectedDay.published}
            selectedCount={Object.keys(currentSelection).length}
            processing={processing}
            onPublish={handlePublish}
          />
        )}

        {error && <p className="text-sm text-destructive">{error}</p>}

        {selectedDay?.published ? (
          <PublishedDayView schedules={selectedDay.schedules} />
        ) : selectedDay?.publishable ? (
          <MenuSelectionList
            menus={menus}
            selection={currentSelection}
            onToggle={toggleMenu}
            onAmountChange={changeAmount}
          />
        ) : (
          <p className="text-sm text-muted-foreground">
            No se puede publicar en esta fecha.
          </p>
        )}
      </div>
    </AppLayout>
  )
}