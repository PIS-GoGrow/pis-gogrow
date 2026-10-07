import { Head, Link } from "@inertiajs/react"
import { Plus, Search, UtensilsCrossed } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import PageContainer from "@/components/page-container"
import PublishedDayView from "@/components/schedules/published-date-view"
import WeekDayTabs from "@/components/schedules/week-day-tabs"
import { Button } from "@/components/ui/button"
import {
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyMedia,
  EmptyTitle,
} from "@/components/ui/empty"
import { Input } from "@/components/ui/input"
import AppLayout from "@/layouts/app-layout"
import { providerMenus, schedules as schedulesRoutes } from "@/routes"
import type { BreadcrumbItem, Schedule } from "@/types"

interface ScheduleDay {
  date: string
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
  days: ScheduleDay[]
}

function weekdayName(isoDate: string) {
  return new Intl.DateTimeFormat("es-UY", { weekday: "long" }).format(
    new Date(`${isoDate}T00:00:00`),
  )
}

function normalize(text: string) {
  return text
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "")
    .toLowerCase()
}

export default function Index({ week, days }: SchedulesIndexProps) {
  const { t } = useTranslation()
  const [selectedDate, setSelectedDate] = useState(days[0]?.date)
  const [search, setSearch] = useState("")

  const selectedDay = days.find((day) => day.date === selectedDate) ?? days[0]

  const query = normalize(search.trim())
  const visibleSchedules =
    selectedDay?.schedules.filter((schedule) =>
      normalize(schedule.menu.name ?? "").includes(query),
    ) ?? []

  const breadcrumbs: BreadcrumbItem[] = [
    { title: "Publicar menú", href: schedulesRoutes.index().url },
  ]

  function handleSelectDate(date: string) {
    setSearch("")
    setSelectedDate(date)
  }

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title="Publicar menú" />

      <PageContainer
        eyebrow="Publicación de menús"
        title="Publicar menú del día"
      >
        <WeekDayTabs
          days={days}
          selectedDate={selectedDay?.date}
          onSelectDate={handleSelectDate}
          previousWeekStart={week.previous_week_start}
          nextWeekStart={week.next_week_start}
        />

        {selectedDay?.schedules.length === 0 && (
          <Empty className="border">
            <EmptyHeader>
              <EmptyMedia variant="icon">
                <UtensilsCrossed aria-hidden="true" />
              </EmptyMedia>
              {selectedDay.publishable ? (
                <>
                  <EmptyTitle>
                    {t("pages.schedules.index.empty.title", {
                      day: weekdayName(selectedDay.date),
                    })}
                  </EmptyTitle>
                  <EmptyDescription>
                    {t("pages.schedules.index.empty.description", {
                      day: weekdayName(selectedDay.date),
                    })}
                  </EmptyDescription>
                </>
              ) : (
                <EmptyTitle>
                  {t("pages.schedules.index.empty_unpublishable.title")}
                </EmptyTitle>
              )}
            </EmptyHeader>
          </Empty>
        )}

        {selectedDay && selectedDay.schedules.length > 0 && (
          <>
            <div className="relative">
              <Input
                value={search}
                onChange={(event) => setSearch(event.target.value)}
                placeholder={t("pages.schedules.index.search_placeholder")}
                aria-label={t("pages.schedules.index.search_label")}
                autoComplete="off"
                className="pr-9"
              />
              <Search
                aria-hidden="true"
                className="text-muted-foreground pointer-events-none absolute top-1/2 right-3 size-4 -translate-y-1/2"
              />
            </div>

            {visibleSchedules.length === 0 ? (
              <Empty className="border">
                <EmptyHeader>
                  <EmptyMedia variant="icon">
                    <UtensilsCrossed aria-hidden="true" />
                  </EmptyMedia>
                  <EmptyTitle>
                    {t("pages.schedules.index.no_results.title")}
                  </EmptyTitle>
                  <EmptyDescription>
                    {t("pages.schedules.index.no_results.description")}
                  </EmptyDescription>
                </EmptyHeader>
              </Empty>
            ) : (
              <PublishedDayView
                schedules={visibleSchedules}
                publishable={selectedDay.publishable}
              />
            )}
          </>
        )}

        <div aria-hidden="true" className="h-16" />

        <div className="bg-background fixed inset-x-0 bottom-[72px] z-20 grid grid-cols-2 gap-3 px-5 py-3 md:inset-x-auto md:right-6 md:bottom-6 md:w-96 md:bg-transparent md:p-0">
          {selectedDay?.publishable ? (
            <Button asChild className="col-start-2">
              <Link href={providerMenus.new().url}>
                <Plus aria-hidden="true" />
                {t("pages.schedules.index.add_dishes")}
              </Link>
            </Button>
          ) : (
            <Button className="col-start-2" disabled>
              <Plus aria-hidden="true" />
              {t("pages.schedules.index.add_dishes")}
            </Button>
          )}
        </div>
      </PageContainer>
    </AppLayout>
  )
}
