import PublishedDayView from "@/components/schedules/published-day-view"
import WeekDayTabs from "@/components/schedules/week-day-tabs"
import AppLayout from "@/layouts/app-layout"
import { schedules as schedulesRoutes } from "@/routes"
import type { BreadcrumbItem, Menu } from "@/types"

//interfaces temporales hasta que este creado el serializer
interface ScheduleDay {
  date: string
  publishable: boolean
  published: boolean
  schedules: {
    id: number
    amount: number
    menu: { id: number; name: string }
  }[]
}

interface SchedulesIndexProps {
  today: string
  max_publish_date: string
  week: {
    starts_on: string
    ends_on: string
    previous_week_start: string | null
    next_week_start: string | null
  }
  menus: Menu[]
  days: ScheduleDay[]
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
        <h1 className="text-xl font-bold">Publicar menú del día</h1>

        <WeekDayTabs
          days={days}
          selectedDate={selectedDate}
          onSelectDate={setSelectedDate}
          previousWeekStart={week.previous_week_start}
          nextWeekStart={week.next_week_start}
        />

        {error && <p className="text-sm text-destructive">{error}</p>}

        {selectedDay?.published ? (
          <PublishedDayView schedules={selectedDay.schedules} />
        ) : selectedDay?.publishable ? (
          <>
            <MenuSelectionList
              menus={menus}
              selection={currentSelection}
              onToggle={toggleMenu}
              onAmountChange={changeAmount}
            />
            <PublishBar
              selectedCount={Object.keys(currentSelection).length}
              processing={processing}
              onPublish={handlePublish}
            />
          </>
        ) : (
          <p className="text-sm text-muted-foreground">
            No se puede publicar en esta fecha.
          </p>
        )}
      </div>
    </AppLayout>
  )
}
