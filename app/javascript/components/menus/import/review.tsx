import { Link, router } from "@inertiajs/react"
import { ChevronLeft, FileText, Trash2 } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import DishCard from "@/components/menus/import/dish-card"
import ImportSummary from "@/components/menus/import/import-summary"
import UpdateDialog from "@/components/menus/import/update-dialog"
import type { AgendaPayload } from "@/components/menus/menu-agenda-fields"
import MenuForm, { type MenuDraft } from "@/components/menus/new-menu-form"
import { Button } from "@/components/ui/button"
import {
  type Agenda,
  type ConfirmedOrders,
  type Dish,
  NO_AGENDA,
  type Preview,
  type SavedMenu,
  canImport,
  entriesPayload,
  fromPreview,
  matchSaved,
  statusOf,
  summarize,
} from "@/lib/menu-import"
import { providerMenuImports, schedules } from "@/routes"

const KEY = "pages.provider_menu_imports.new"

// El formulario de plato se alimenta de un plato guardado. Acá todavía no
// existe, así que se le arma uno con lo que trae la tarjeta; los grupos van sin
// id porque ninguno está guardado.
function asMenu(dish: Dish) {
  return {
    name: dish.name,
    description: dish.description,
    price: dish.price === "" ? null : Number(dish.price),
    option_groups: dish.option_groups,
  }
}

function toAgenda(payload: AgendaPayload): Agenda {
  if (payload.mode === "none") return NO_AGENDA

  return {
    mode: payload.mode,
    weekdays: payload.weekdays,
    date: payload.date || null,
    starts_on: payload.starts_on || null,
    ends_on: payload.ends_on || null,
    amount: null,
  }
}

interface ReviewProps {
  preview: Preview
  savedMenus: SavedMenu[]
  today: string
  maximumPublishDate: string
  onRestart: () => void
}

// La planilla ya leída, para revisarla antes de importar. Vive acá y no en la
// pantalla porque se reinicia con cada archivo: la pantalla la monta con la
// clave de la vista previa.
export default function Review({
  preview,
  savedMenus,
  today,
  maximumPublishDate,
  onRestart,
}: ReviewProps) {
  const { t } = useTranslation()

  const [dishes, setDishes] = useState<Dish[]>(() => fromPreview(preview))
  const [editing, setEditing] = useState<string | null>(null)
  const [updating, setUpdating] = useState<string | null>(null)
  const [importing, setImporting] = useState(false)

  const counts = summarize(dishes, savedMenus)
  const editingDish = dishes.find((dish) => dish.key === editing) ?? null

  function change(key: string, values: Partial<Dish>) {
    setDishes((prev) =>
      prev.map((dish) => (dish.key === key ? { ...dish, ...values } : dish)),
    )
  }

  function applyDraft(key: string, values: MenuDraft) {
    change(key, {
      name: values.name,
      description: values.description,
      price: values.price,
      option_groups: values.option_groups,
      agenda: toAgenda(values.agenda),
      // El formulario no deja guardar un plato incompleto: lo que venía mal en
      // la planilla quedó corregido acá.
      errors: [],
    })
    setEditing(null)
  }

  // Avisar antes de pisar un plato guardado solo tiene sentido si hay pedidos
  // confirmados en juego; si no los hay, se aplica derecho.
  function askUpdate(dish: Dish) {
    const match = matchSaved(dish.name, savedMenus)

    if (match && match.confirmed_orders > 0) return setUpdating(dish.key)

    change(dish.key, { action: "update", confirmed_orders: "keep" })
  }

  function applyUpdate(confirmedOrders: ConfirmedOrders) {
    if (updating) {
      change(updating, { action: "update", confirmed_orders: confirmedOrders })
    }
    setUpdating(null)
  }

  function send() {
    setImporting(true)
    router.post(
      providerMenuImports.confirm().url,
      {
        preview_id: preview.id,
        filename: preview.filename,
        entries: entriesPayload(dishes, savedMenus),
      } as never,
      {
        preserveState: true,
        preserveScroll: true,
        // Lo que recién se ve al guardar vuelve a la tarjeta que lo produjo.
        onSuccess: (page) => {
          const failed = (
            page.props as { row_errors?: Record<string, string[]> }
          ).row_errors

          if (!failed || Object.keys(failed).length === 0) return

          setDishes((prev) =>
            prev.map((dish) =>
              failed[dish.key] ? { ...dish, errors: failed[dish.key] } : dish,
            ),
          )
        },
        onFinish: () => setImporting(false),
      },
    )
  }

  if (editingDish) {
    const match = matchSaved(editingDish.name, savedMenus)

    return (
      <>
        <div className="relative flex h-9 items-center justify-center">
          <Button
            variant="ghost"
            size="icon"
            className="absolute left-0 -ml-2"
            aria-label={t(`${KEY}.back`)}
            onClick={() => setEditing(null)}
          >
            <ChevronLeft aria-hidden="true" className="size-5" />
          </Button>
          <h1 className="text-lg font-semibold">{t(`${KEY}.edit.title`)}</h1>
        </div>

        <MenuForm
          menu={asMenu(editingDish) as never}
          draft={{
            today,
            maximum_publish_date: maximumPublishDate,
            agenda: editingDish.agenda ?? match?.agenda ?? NO_AGENDA,
          }}
          onSaveDraft={(values) => applyDraft(editingDish.key, values)}
          onCancelDraft={() => setEditing(null)}
        />
      </>
    )
  }

  return (
    <>
      <div className="relative flex h-9 items-center justify-center">
        <Button
          variant="ghost"
          size="icon"
          className="absolute left-0 -ml-2"
          aria-label={t(`${KEY}.back`)}
          asChild
        >
          <Link href={schedules.index().url}>
            <ChevronLeft aria-hidden="true" className="size-5" />
          </Link>
        </Button>
        <h1 className="text-lg font-semibold">{t(`${KEY}.title`)}</h1>
      </div>

      <div className="flex items-center gap-3 rounded-lg border p-3">
        <FileText
          aria-hidden="true"
          className="text-muted-foreground size-5 shrink-0"
        />
        <p className="min-w-0 flex-1 truncate text-sm font-medium">
          {preview.filename}
        </p>
        <Button
          variant="ghost"
          size="icon-sm"
          aria-label={t(`${KEY}.upload.remove`)}
          onClick={onRestart}
        >
          <Trash2 aria-hidden="true" />
        </Button>
      </div>

      <ImportSummary counts={counts} />

      <div className="flex flex-col gap-3">
        {dishes.map((dish) => (
          <DishCard
            key={dish.key}
            dish={dish}
            status={statusOf(dish, savedMenus)}
            onRemove={() =>
              setDishes((prev) =>
                prev.filter((other) => other.key !== dish.key),
              )
            }
            onEdit={() => setEditing(dish.key)}
            onDuplicate={() => change(dish.key, { action: "create" })}
            onUpdate={() => askUpdate(dish)}
            onReset={() =>
              change(dish.key, { action: null, confirmed_orders: "keep" })
            }
          />
        ))}
      </div>

      <div className="flex flex-col gap-3">
        <Button
          className="h-11"
          disabled={!canImport(dishes, savedMenus) || importing}
          onClick={send}
        >
          {t(`${KEY}.import`)}
        </Button>

        {counts.error > 0 && (
          <p className="text-muted-foreground text-center text-xs">
            {t(`${KEY}.blocked`)}
          </p>
        )}

        <Button variant="secondary" className="h-11" asChild>
          <Link href={schedules.index().url}>{t(`${KEY}.cancel`)}</Link>
        </Button>
      </div>

      <UpdateDialog
        key={updating ?? "none"}
        open={updating !== null}
        onOpenChange={(open) => !open && setUpdating(null)}
        onApply={applyUpdate}
      />
    </>
  )
}
