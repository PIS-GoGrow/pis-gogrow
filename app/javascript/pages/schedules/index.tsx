import { Head, Link, router } from "@inertiajs/react"
import { Plus } from "lucide-react"
import { useState } from "react"

import CreateMenuDialog from "@/components/menus/create-menu-dialog"
import PageContainer from "@/components/page-container"
import MenuSelectionList from "@/components/schedules/menu-selection-list"
import PublishBar from "@/components/schedules/publish-bar"
import PublishedDayView from "@/components/schedules/published-date-view"
import WeekDayTabs from "@/components/schedules/week-day-tabs"
import { Button } from "@/components/ui/button"
import { DialogTrigger } from "@/components/ui/dialog"
import AppLayout from "@/layouts/app-layout"
import {
  providerMenus as menusRoutes,
  schedules as schedulesRoutes,
} from "@/routes"
import type { BreadcrumbItem, Menu, Schedule } from "@/types"

interface ScheduleDay {
  date: string
  published: boolean
  publishable: boolean
  schedules: Schedule[]
}

interface ScheduleWeek {
  starts_on: string
  ends_on: string
  previous_week_start: string | null
  next_week_start: string | null
}

interface SchedulesIndexProps {
  week: ScheduleWeek
  menus: Menu[]
  days: ScheduleDay[]
}

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

  function handleSelectDate(date: string) {
    setError(null)
    setSelectedDate(date)
  }

  function toggleMenu(menuId: number) {
    setError(null)

    if (!selectedDate) return

    setSelections((prev) => {
      const daySelection = { ...(prev[selectedDate] ?? {}) }
      if (menuId in daySelection) delete daySelection[menuId]
      else daySelection[menuId] = ""
      return { ...prev, [selectedDate]: daySelection }
    })
  }

  function changeAmount(menuId: number, value: string) {
    setError(null)

    if (!selectedDate) return

    setSelections((prev) => ({
      ...prev,
      [selectedDate]: { ...(prev[selectedDate] ?? {}), [menuId]: value },
    }))
  }

  function handlePublish() {
    if (!selectedDate) return

    const selectedItems = Object.entries(currentSelection)

    if (selectedItems.length === 0) {
      setError("Seleccione al menos un plato.")
      return
    }

    if (selectedItems.some(([, amount]) => amount === "")) {
      setError("Todos los platos seleccionados deben tener un stock.")
      return
    }

    const items = selectedItems.map(([menuId, amount]) => ({
      menu_id: Number(menuId),
      amount: Number(amount),
    }))

    // Validaciones del punto 14 del documento: mejoran la UX, pero nunca
    // sustituyen las validaciones que Rails vuelve a hacer del lado del servidor.

    if (items.some((item) => item.amount <= 0)) {
      setError("El stock de todos los platos debe ser mayor que cero.")
      return
    }

    setProcessing(true)
    setError(null)

    router.post(
      schedulesRoutes.create().url,
      { date: selectedDate, items },
      {
        preserveState: true,
        preserveScroll: true,
        onError: (errors) => {
          // seleccion se mantiene a proposito para no cambiar lo que el proveedor toco
          setError(
            Object.values(errors).flat()[0] ?? "No se pudo publicar el menú.",
          )
        },
        onFinish: () => setProcessing(false),
      },
    )
  }

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title="Publicar menú" />

      <CreateMenuDialog>
        <PageContainer
          eyebrow="Publicación de menús"
          title="Publicar menú del día"
          actions={
            <DialogTrigger className="ml-auto" asChild>
              <Button>Agregar plato</Button>
            </DialogTrigger>
          }
        >
          <WeekDayTabs
            days={days}
            selectedDate={selectedDate}
            onSelectDate={handleSelectDate}
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

          {error && <p className="text-destructive text-sm">{error}</p>}

          {!selectedDay ? (
            <p className="text-muted-foreground text-sm">
              No hay ninguna fecha seleccionada.
            </p>
          ) : selectedDay?.published ? (
            <PublishedDayView schedules={selectedDay.schedules} />
          ) : selectedDay?.publishable ? (
            <MenuSelectionList
              menus={menus}
              selection={currentSelection}
              onToggle={toggleMenu}
              onAmountChange={changeAmount}
            />
          ) : (
            <p className="text-muted-foreground text-sm">
              No se puede publicar en esta fecha.
            </p>
          )}
        </PageContainer>
      </CreateMenuDialog>
    </AppLayout>
  )
}
