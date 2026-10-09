import { router } from "@inertiajs/react"
import { ListFilter, Minus, Plus, Search, UtensilsCrossed } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import { DatePicker } from "@/components/date-picker"
import { Button } from "@/components/ui/button"
import {
  Card,
  CardAction,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import {
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyMedia,
  EmptyTitle,
} from "@/components/ui/empty"
import { Field, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group"
import { useFormatters } from "@/hooks/use-formatters"
import { normalizeText } from "@/lib/normalize-text"
import { cn } from "@/lib/utils"
import { providerMenus } from "@/routes"
import type { ProviderMenusNew, SavedMenu } from "@/types"

const FILTERS = ["all", "available", "added"] as const
type Filter = (typeof FILTERS)[number]

const WEEKDAYS = [1, 2, 3, 4, 5]
const key = "pages.provider_menus.new.saved"

interface SavedMenusTabProps {
  menus: SavedMenu[]
  published: ProviderMenusNew["published"]
  today: string
  maximumPublishDate: string
  onPublished: (date: string) => void
  defaultDate: string | null
}

function SavedMenuCard({
  menu,
  selected,
  disabled,
  onToggle,
}: {
  menu: SavedMenu
  selected: boolean
  disabled: boolean
  onToggle?: () => void
}) {
  const { t } = useTranslation()
  const { formatMoneyShort } = useFormatters()

  return (
    <Card className={cn("w-full", disabled && "opacity-50")}>
      <CardHeader>
        <CardTitle>
          {menu.name}{" "}
          <span className="text-muted-foreground">
            | {formatMoneyShort(menu.price ?? 0)}
          </span>
        </CardTitle>
        <CardDescription>{menu.description}</CardDescription>
        <CardAction>
          <Button
            type="button"
            size="icon"
            variant={selected ? "default" : "outline"}
            className={cn(
              selected && "bg-blue-600 text-white hover:bg-blue-700",
            )}
            disabled={disabled}
            aria-pressed={selected}
            aria-label={t(selected ? `${key}.unselect` : `${key}.select`, {
              name: menu.name,
            })}
            onClick={onToggle}
          >
            {selected ? (
              <Minus aria-hidden="true" />
            ) : (
              <Plus aria-hidden="true" />
            )}
          </Button>
        </CardAction>
      </CardHeader>
      <CardContent>
        {/* Mismos días que en "Platos nuevos", pero solo de lectura. */}
        <ToggleGroup
          type="multiple"
          variant="outline"
          spacing={2}
          value={menu.weekdays.map(String)}
          inert
          aria-hidden="true"
        >
          {WEEKDAYS.map((day) => (
            <ToggleGroupItem
              key={day}
              value={String(day)}
              className="data-[state=on]:border-primary data-[state=on]:bg-primary/10 size-10"
            >
              {t(`pages.provider_menus.edit.agenda.weekdays.${day}`)}
            </ToggleGroupItem>
          ))}
        </ToggleGroup>
        <span className="sr-only">
          {menu.weekdays
            .map((day) =>
              t(`pages.provider_menus.edit.agenda.weekday_names.${day}`),
            )
            .join(", ")}
        </span>
      </CardContent>
    </Card>
  )
}

export default function SavedMenusTab({
  menus,
  published,
  today,
  maximumPublishDate,
  onPublished,
  defaultDate,
}: SavedMenusTabProps) {
  const { t } = useTranslation()
  const [date, setDate] = useState(defaultDate ?? "")
  const [filter, setFilter] = useState<Filter>("all")
  const [search, setSearch] = useState("")
  const [selected, setSelected] = useState<number[]>([])
  const [processing, setProcessing] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const publishedIds = new Set(
    published.filter((item) => item.date === date).map((item) => item.menu_id),
  )
  const query = normalizeText(search.trim())
  const matching = menus.filter((menu) =>
    normalizeText(menu.name ?? "").includes(query),
  )
  const available =
    filter === "added"
      ? []
      : matching.filter((menu) => !publishedIds.has(menu.id))
  const added =
    filter === "available"
      ? []
      : matching.filter((menu) => publishedIds.has(menu.id))

  function changeDate(value: string) {
    setDate(value)
    setSelected([])
    setError(null)
  }

  function toggle(id: number) {
    setSelected((current) =>
      current.includes(id)
        ? current.filter((item) => item !== id)
        : [...current, id],
    )
  }

  function submit() {
    setProcessing(true)
    setError(null)

    router.post(
      providerMenus.publish().url,
      { date, menu_ids: selected },
      {
        preserveScroll: true,
        preserveState: true,
        onSuccess: () => {
          setSelected([])
          onPublished(date)
        },
        onError: (errors) => {
          const first = Object.values(errors)[0]
          setError((Array.isArray(first) ? first[0] : first) ?? null)
        },
        onFinish: () => setProcessing(false),
      },
    )
  }

  if (menus.length === 0) {
    return (
      <Empty className="border">
        <EmptyHeader>
          <EmptyMedia variant="icon">
            <UtensilsCrossed aria-hidden="true" />
          </EmptyMedia>
          <EmptyTitle>{t(`${key}.no_saved.title`)}</EmptyTitle>
          <EmptyDescription>
            {t(`${key}.no_saved.description`)}
          </EmptyDescription>
        </EmptyHeader>
      </Empty>
    )
  }

  return (
    <div className="flex flex-col gap-4">
      <Field>
        <FieldLabel htmlFor="saved-date">{t(`${key}.date_label`)}</FieldLabel>
        <DatePicker
          id="saved-date"
          value={date}
          onChange={changeDate}
          min={today}
          max={maximumPublishDate}
          weekdaysOnly
        />
      </Field>

      {!date ? (
        <p className="text-muted-foreground text-sm">{t(`${key}.date_hint`)}</p>
      ) : (
        <>
          <div className="flex gap-2">
            <div className="relative flex-1">
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

            <Select
              value={filter}
              onValueChange={(value) => setFilter(value as Filter)}
            >
              <SelectTrigger
                aria-label={t(`${key}.filter_label`)}
                className="w-fit"
              >
                <ListFilter aria-hidden="true" className="size-4" />
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {FILTERS.map((item) => (
                  <SelectItem key={item} value={item}>
                    {t(`${key}.filters.${item}`)}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          {available.length + added.length === 0 && (
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
          )}

          {available.map((menu) => (
            <SavedMenuCard
              key={menu.id}
              menu={menu}
              selected={selected.includes(menu.id)}
              disabled={false}
              onToggle={() => toggle(menu.id)}
            />
          ))}

          {added.length > 0 && (
            <>
              <p
                role="note"
                className="rounded-md bg-green-50 px-3 py-2 text-sm text-green-800 dark:bg-green-950 dark:text-green-200"
              >
                {t(`${key}.already_added`)}
              </p>
              {added.map((menu) => (
                <SavedMenuCard
                  key={menu.id}
                  menu={menu}
                  selected={false}
                  disabled
                />
              ))}
            </>
          )}
        </>
      )}

      {error && (
        <p role="alert" className="text-destructive text-sm">
          {error}
        </p>
      )}

      <div aria-hidden="true" className="h-16" />

      <div className="bg-background fixed inset-x-0 bottom-[72px] z-20 px-5 py-3 md:inset-x-auto md:right-6 md:bottom-6 md:w-96 md:bg-transparent md:p-0">
        <Button
          type="button"
          className="w-full"
          disabled={selected.length === 0 || processing}
          onClick={submit}
        >
          {processing ? t(`${key}.submitting`) : t(`${key}.submit`)}
        </Button>
      </div>
    </div>
  )
}
