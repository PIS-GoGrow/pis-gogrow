import { Link, useForm } from "@inertiajs/react"
import { Pencil, Plus, Trash2 } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import EditMenuSheet, {
  type ConfirmedOrders,
  type EditScope,
} from "@/components/menus/edit-menu-sheet"
import MenuAgendaFields, {
  type AgendaDraft,
  agendaPayload,
  initialAgenda,
} from "@/components/menus/menu-agenda-fields"
import { QuantityInput } from "@/components/quantity-input"
import { Button } from "@/components/ui/button"
import { Field, FieldDescription, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { Separator } from "@/components/ui/separator"
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetFooter,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet"
import { Textarea } from "@/components/ui/textarea"
import { providerMenus as menusRoutes, schedules } from "@/routes"
import type { Menu, ProviderMenusEdit, ProviderMenusNew } from "@/types"

interface OptionGroupDraft {
  id?: number
  name: string
  options: string
  limit: number
}

const emptyDraft: OptionGroupDraft = { name: "", options: "", limit: 1 }

interface MenuFormProps {
  menu?: Menu
  edit?: ProviderMenusEdit
  create?: ProviderMenusNew
  onCreated?: () => void
}

function agendaIsComplete(agenda: AgendaDraft) {
  if (agenda.weekdays.length === 0) return true
  if (!(Number(agenda.amount) > 0)) return false
  if (agenda.mode === "single") return agenda.date !== ""
  if (agenda.mode === "range")
    return agenda.starts_on !== "" && agenda.ends_on >= agenda.starts_on

  return agenda.starts_on !== ""
}

export default function MenuForm({
  menu,
  edit,
  create,
  onCreated,
}: MenuFormProps) {
  const { t } = useTranslation()
  const key = "pages.provider_menus.form"
  const calendar = edit ?? create

  const [groups, setGroups] = useState<OptionGroupDraft[]>(() =>
    menu
      ? menu.option_groups.map((group) => ({
          id: group.id,
          name: group.name,
          options: group.options.join(", "),
          limit: group.limit,
        }))
      : [],
  )

  const [removedGroupIds, setRemovedGroupIds] = useState<number[]>([])
  const [groupSheetOpen, setGroupSheetOpen] = useState(false)
  const [editingIndex, setEditingIndex] = useState<number | null>(null)
  const [draft, setDraft] = useState<OptionGroupDraft>(emptyDraft)
  const [saveSheetOpen, setSaveSheetOpen] = useState(false)
  const [saved, setSaved] = useState(false)
  const [agenda, setAgenda] = useState<AgendaDraft | null>(() =>
    edit
      ? initialAgenda(edit.agenda)
      : create
        ? initialAgenda({
            mode: "none",
            weekdays: [],
            date: null,
            starts_on: null,
            ends_on: null,
            amount: null,
          })
        : null,
  )
  const [agendaError, setAgendaError] = useState<string | null>(null)

  const {
    data,
    setData,
    post,
    patch,
    processing,
    errors,
    setError,
    clearErrors,
    transform,
  } = useForm({
    name: menu?.name ?? "",
    description: menu?.description ?? "",
    price: menu?.price?.toString() ?? "",
  })

  const draftOptions = draft.options
    .split(",")
    .map((o) => o.trim())
    .filter(Boolean)

  const normalizedDraftOptions = draftOptions.map((option) =>
    option.toLocaleLowerCase("es"),
  )

  const hasDuplicateOptions =
    new Set(normalizedDraftOptions).size !== normalizedDraftOptions.length

  const canSaveDraft =
    draft.name.trim() !== "" && draftOptions.length > 0 && !hasDuplicateOptions

  function openAddGroupSheet() {
    setEditingIndex(null)
    setDraft(emptyDraft)
    setGroupSheetOpen(true)
  }

  function openEditGroupSheet(index: number) {
    setEditingIndex(index)
    setDraft(groups[index])
    setGroupSheetOpen(true)
  }

  function saveDraft() {
    if (!canSaveDraft) return

    const groupToSave: OptionGroupDraft = {
      ...draft,
      limit: Math.min(draft.limit, draftOptions.length),
    }

    setGroups((prev) =>
      editingIndex === null
        ? [...prev, groupToSave]
        : prev.map((g, i) => (i === editingIndex ? groupToSave : g)),
    )

    setGroupSheetOpen(false)
  }

  function removeGroup(index: number) {
    const group = groups[index]

    if (group.id !== undefined) {
      setRemovedGroupIds((prev) => [...prev, group.id!])
    }

    setGroups((prev) => prev.filter((_, i) => i !== index))
  }

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault()

    for (const field of ["name", "price", "description"] as const) {
      if (data[field].trim() === "") {
        setError(field, [t(`${key}.required`)])
        return
      }
    }

    if (agenda && !agendaIsComplete(agenda)) {
      setAgendaError(t("pages.provider_menus.edit.agenda.incomplete"))
      return
    }

    setAgendaError(null)

    if (edit) {
      transform((formData) => ({ menu: menuPayload(formData) }))
      setSaved(false)
      setSaveSheetOpen(true)
      return
    }

    transform((formData) => ({
      menu: menuPayload(formData),
      ...(agenda ? { agenda: agendaPayload(agenda) } : {}),
    }))

    post(menusRoutes.create().url, {
      preserveState: true,
      preserveScroll: true,
      onSuccess: () => onCreated?.(),
    })
  }

  function menuPayload(formData: typeof data) {
    return {
      ...formData,
      option_groups_attributes: [
        ...groups.map((g) => ({
          ...(g.id !== undefined ? { id: g.id } : {}),
          name: g.name,
          options: g.options
            .split(",")
            .map((o) => o.trim())
            .filter(Boolean),
          limit: g.limit,
        })),
        ...removedGroupIds.map((id) => ({
          id,
          _destroy: true,
        })),
      ],
    }
  }

  function applyChanges(scope: EditScope, confirmedOrders: ConfirmedOrders) {
    if (!edit || !agenda) return

    transform((formData) => ({
      menu: menuPayload(formData),
      agenda: agendaPayload(agenda),
      scope,
      confirmed_orders: confirmedOrders,
      schedule_id: new URLSearchParams(window.location.search).get(
        "schedule_id",
      ),
    }))

    patch(menusRoutes.update(edit.saved_menu_id).url, {
      preserveScroll: true,
      preserveState: true,
      onSuccess: () => setSaved(true),
      onError: () => {
        setSaveSheetOpen(false)
      },
    })
  }

  const serverAgendaError = (errors as Record<string, string | undefined>)
    .agenda

  return (
    <>
      <form
        onSubmit={handleSubmit}
        className={menu ? "mx-auto w-full max-w-3xl" : undefined}
      >
        <div className="flex flex-col gap-4">
          <div className="flex items-start gap-3">
            <Field data-invalid={!!errors.name?.length} className="flex-1">
              <FieldLabel htmlFor="name">
                <span>
                  {t(`${key}.name`)}
                  <span className="text-destructive">*</span>
                </span>
              </FieldLabel>
              <Input
                id="name"
                type="text"
                name="name"
                placeholder={t(`${key}.name_placeholder`)}
                value={data.name}
                onChange={(e) => {
                  setData("name", e.target.value)
                  clearErrors("name")
                }}
              />
              {!!errors.name?.length && (
                <FieldDescription>{errors.name}</FieldDescription>
              )}
            </Field>

            <Field data-invalid={!!errors.price?.length} className="w-24">
              <FieldLabel htmlFor="price">
                <span>
                  {t(`${key}.price`)}
                  <span className="text-destructive">*</span>
                </span>
              </FieldLabel>
              <div className="relative">
                <span
                  aria-hidden="true"
                  className="text-muted-foreground pointer-events-none absolute inset-y-0 left-3 flex items-center text-sm"
                >
                  $
                </span>
                <Input
                  id="price"
                  type="number"
                  inputMode="decimal"
                  min="0.01"
                  step="0.01"
                  name="price"
                  className="[appearance:textfield] pl-6 [&::-webkit-inner-spin-button]:appearance-none [&::-webkit-outer-spin-button]:appearance-none"
                  value={data.price}
                  onChange={(e) => {
                    setData("price", e.target.value)
                    clearErrors("price")
                  }}
                />
              </div>
              {!!errors.price?.length && (
                <FieldDescription>{errors.price}</FieldDescription>
              )}
            </Field>
          </div>

          <Field data-invalid={!!errors.description?.length}>
            <FieldLabel htmlFor="description">
              <span>
                {t(`${key}.description`)}
                <span className="text-destructive">*</span>
              </span>
            </FieldLabel>
            <Textarea
              id="description"
              name="description"
              placeholder={t(`${key}.description_placeholder`)}
              value={data.description}
              className="min-h-24 resize-none"
              onChange={(e) => {
                setData("description", e.target.value)
                clearErrors("description")
              }}
            />

            {!!errors.description?.length && (
              <FieldDescription>{errors.description}</FieldDescription>
            )}
          </Field>

          <div className="flex flex-col gap-3">
            <div className="flex items-center justify-between">
              <FieldLabel>{t(`${key}.options.title`)}</FieldLabel>

              <Button
                type="button"
                variant="ghost"
                size="sm"
                className="-mr-2"
                onClick={openAddGroupSheet}
              >
                <Plus aria-hidden="true" className="h-4 w-4" />
                {t(`${key}.options.add`)}
              </Button>
            </div>
            {groups.length === 0 ? (
              <p className="text-muted-foreground text-sm">
                {t(`${key}.options.empty`)}
              </p>
            ) : (
              <div className="flex flex-col gap-3">
                {groups.map((group, index) => (
                  <div
                    key={group.id ?? index}
                    className="bg-background rounded-xl border p-4"
                  >
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-medium">{group.name}</span>

                      <div className="flex items-center gap-1">
                        <Button
                          type="button"
                          variant="ghost"
                          size="icon-sm"
                          aria-label={t(`${key}.options.edit`, {
                            name: group.name,
                          })}
                          onClick={() => openEditGroupSheet(index)}
                        >
                          <Pencil aria-hidden="true" className="h-4 w-4" />
                        </Button>

                        <Button
                          type="button"
                          variant="ghost"
                          size="icon-sm"
                          aria-label={t(`${key}.options.remove`, {
                            name: group.name,
                          })}
                          onClick={() => removeGroup(index)}
                        >
                          <Trash2 aria-hidden="true" className="h-4 w-4" />
                        </Button>
                      </div>
                    </div>

                    <Separator className="my-2" />

                    <div className="text-muted-foreground flex items-start justify-between gap-2 text-xs">
                      <span>{group.options}</span>
                      <span className="shrink-0">
                        {t(`${key}.options.limit`, { limit: group.limit })}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {calendar && agenda && (
          <div className="mt-6">
            <MenuAgendaFields
              value={agenda}
              onChange={(value) => {
                setAgenda(value)
                setAgendaError(null)
              }}
              today={calendar.today}
              maximumPublishDate={calendar.maximum_publish_date}
              error={agendaError ?? serverAgendaError}
            />
          </div>
        )}

        {menu ? (
          <div className="mt-8 flex justify-end gap-3">
            <Button type="button" variant="outline" asChild>
              <Link href={menusRoutes.index().url}>{t(`${key}.cancel`)}</Link>
            </Button>

            <Button type="submit" disabled={processing}>
              {processing ? t(`${key}.updating`) : t(`${key}.update`)}
            </Button>
          </div>
        ) : (
          <div className="mt-8 grid grid-cols-2 gap-3">
            <Button type="button" variant="secondary" className="h-11" asChild>
              <Link href={schedules.index().url}>{t(`${key}.cancel`)}</Link>
            </Button>

            <Button type="submit" className="h-11" disabled={processing}>
              {processing ? t(`${key}.creating`) : t(`${key}.create`)}
            </Button>
          </div>
        )}
      </form>

      <Sheet open={groupSheetOpen} onOpenChange={setGroupSheetOpen}>
        <SheetContent
          side="bottom"
          showCloseButton={false}
          className="mx-auto gap-0 rounded-t-3xl pb-[env(safe-area-inset-bottom)] md:max-w-xl"
        >
          <div className="bg-muted-foreground/30 mx-auto mt-3 h-1 w-10 rounded-full" />

          <SheetHeader className="items-start px-6 pt-8 text-left">
            <SheetTitle className="text-base">
              {t(`${key}.group.title`)}
            </SheetTitle>
            <SheetDescription className="sr-only">
              {t(`${key}.group.description`)}
            </SheetDescription>
          </SheetHeader>

          <div className="flex flex-col gap-4 px-6 pt-2">
            <Field>
              <FieldLabel htmlFor="group-name">
                {t(`${key}.group.name`)}
              </FieldLabel>

              <Input
                id="group-name"
                type="text"
                placeholder={t(`${key}.group.name_placeholder`)}
                value={draft.name}
                onChange={(e) =>
                  setDraft((prev) => ({ ...prev, name: e.target.value }))
                }
              />
            </Field>

            <Field>
              <FieldLabel htmlFor="group-options">
                {t(`${key}.group.options`)}
              </FieldLabel>

              <Textarea
                id="group-options"
                spellCheck={false}
                placeholder={t(`${key}.group.options_placeholder`)}
                className="min-h-20 resize-none"
                value={draft.options}
                onChange={(e) =>
                  setDraft((prev) => ({ ...prev, options: e.target.value }))
                }
              />

              <FieldDescription>
                {t(`${key}.group.options_hint`)}
              </FieldDescription>

              {hasDuplicateOptions && (
                <p className="text-destructive text-sm">
                  {t(`${key}.group.duplicates`)}
                </p>
              )}
            </Field>

            <Field>
              <FieldLabel>{t(`${key}.group.limit`)}</FieldLabel>

              <div>
                <QuantityInput
                  value={Math.min(
                    draft.limit,
                    Math.max(draftOptions.length, 1),
                  )}
                  max={Math.max(draftOptions.length, 1)}
                  onChange={(value) =>
                    setDraft((prev) => ({ ...prev, limit: value }))
                  }
                />
              </div>
            </Field>
          </div>

          <SheetFooter className="grid grid-cols-2 gap-3 px-6 pt-6 pb-6">
            <Button
              type="button"
              variant="secondary"
              className="h-11"
              onClick={() => setGroupSheetOpen(false)}
            >
              {t(`${key}.group.cancel`)}
            </Button>

            <Button
              type="button"
              className="h-11"
              disabled={!canSaveDraft}
              onClick={saveDraft}
            >
              {editingIndex === null
                ? t(`${key}.group.add`)
                : t(`${key}.group.modify`)}
            </Button>
          </SheetFooter>
        </SheetContent>
      </Sheet>

      {edit && agenda && (
        <EditMenuSheet
          open={saveSheetOpen}
          onOpenChange={setSaveSheetOpen}
          saved={saved}
          processing={processing}
          agenda={agendaPayload(agenda)}
          today={edit.today}
          scheduledDays={edit.scheduled_days}
          onApply={applyChanges}
        />
      )}
    </>
  )
}
