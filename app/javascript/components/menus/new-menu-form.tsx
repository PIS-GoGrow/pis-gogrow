import { Link, useForm } from "@inertiajs/react"
import { Pencil, Plus, Trash2 } from "lucide-react"
import { useState } from "react"

import { QuantityInput } from "@/components/quantity-input"
import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
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
import { providerMenus as menusRoutes } from "@/routes"
import type { Menu } from "@/types"

interface OptionGroupDraft {
  id?: number
  name: string
  options: string
  limit: number
}

const emptyDraft: OptionGroupDraft = { name: "", options: "", limit: 1 }

interface MenuFormProps {
  formSuccess?: () => void
  menu?: Menu
}

export default function MenuForm({ formSuccess, menu }: MenuFormProps) {
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
  const [groupDialogOpen, setGroupDialogOpen] = useState(false)
  const [editingIndex, setEditingIndex] = useState<number | null>(null)
  const [draft, setDraft] = useState<OptionGroupDraft>(emptyDraft)
  const [saveSheetOpen, setSaveSheetOpen] = useState(false)
  const [saveSheetStage, setSaveSheetStage] = useState<"confirm" | "saved">(
    "confirm",
  )

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

  function openAddGroupDialog() {
    setEditingIndex(null)
    setDraft(emptyDraft)
    setGroupDialogOpen(true)
  }

  function openEditGroupDialog(index: number) {
    setEditingIndex(index)
    setDraft(groups[index])
    setGroupDialogOpen(true)
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

    setGroupDialogOpen(false)
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

    if (data.name === "") {
      setError("name", ["No puede estar vacío."])
      return
    }

    if (data.description.trim() === "") {
      setError("description", ["No puede estar vacío."])
      return
    }

    if (data.price === "") {
      setError("price", ["No puede estar vacío."])
      return
    }

    transform((formData) => ({
      menu: {
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
      },
    }))

    if (menu) {
      setSaveSheetStage("confirm")
      setSaveSheetOpen(true)
      return
    }

    post(menusRoutes.create().url, {
      onSuccess: () => formSuccess?.(),
    })
  }

  function applyChanges() {
    if (!menu) return

    patch(menusRoutes.update(menu.id).url, {
      preserveScroll: true,
      preserveState: true,
      onSuccess: () => {
        setSaveSheetStage("saved")
        formSuccess?.()
      },
      onError: () => {
        setSaveSheetOpen(false)
        setSaveSheetStage("confirm")
      },
    })
  }

  return (
    <>
      <form
        onSubmit={handleSubmit}
        className={menu ? "mx-auto w-full max-w-3xl" : undefined}
      >
        <div className="flex flex-col gap-3">
          <Field data-invalid={!!errors.name?.length}>
            <FieldLabel htmlFor="name">
              Nombre <span className="text-destructive">*</span>
            </FieldLabel>
            <Input
              type="text"
              name="name"
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

          <Field
            data-invalid={!!errors.description?.length}
            className={menu ? "sm:col-span-2" : undefined}
          >
            <FieldLabel htmlFor="description">
              Descripción <span className="text-destructive">*</span>
            </FieldLabel>
            <Textarea
              name="description"
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

          <Field
            data-invalid={!!errors.price?.length}
            className={menu ? "sm:col-start-2 sm:row-start-1" : undefined}
          >
            <FieldLabel htmlFor="price">
              Precio <span className="text-destructive">*</span>
            </FieldLabel>
            <Input
              type="number"
              min="0.01"
              step="0.01"
              name="price"
              value={data.price}
              onChange={(e) => {
                setData("price", e.target.value)
                clearErrors("price")
              }}
            />
            {!!errors.price?.length && (
              <FieldDescription>{errors.price}</FieldDescription>
            )}
          </Field>

          <div
            className={
              menu ? "flex flex-col gap-3 sm:col-span-2" : "flex flex-col gap-2"
            }
          >
            <div className="flex items-center justify-between">
              <FieldLabel className="text-base font-semibold">
                Opciones
              </FieldLabel>

              <Button
                type="button"
                variant="ghost"
                size="sm"
                onClick={openAddGroupDialog}
              >
                <Plus aria-hidden="true" className="h-4 w-4" />
                Agregar
              </Button>
            </div>
            {groups.length === 0 ? (
              <p className="text-muted-foreground py-2 text-sm">
                ¿Tiene sabores para elegir? ¡Agrégalos!
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
                          aria-label={`Editar ${group.name}`}
                          onClick={() => openEditGroupDialog(index)}
                        >
                          <Pencil aria-hidden="true" className="h-4 w-4" />
                        </Button>

                        <Button
                          type="button"
                          variant="ghost"
                          size="icon-sm"
                          aria-label={`Borrar ${group.name}`}
                          onClick={() => removeGroup(index)}
                        >
                          <Trash2 aria-hidden="true" className="h-4 w-4" />
                        </Button>
                      </div>
                    </div>

                    <Separator className="my-2" />

                    <div className="text-muted-foreground flex items-start justify-between gap-2 text-sm">
                      <span>{group.options}</span>
                      <span className="shrink-0">Límite {group.limit}</span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        <Dialog open={groupDialogOpen} onOpenChange={setGroupDialogOpen}>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Agregá opciones</DialogTitle>
            </DialogHeader>

            <div className="flex flex-col gap-3">
              <Field>
                <FieldLabel htmlFor="group-name">Nombre del grupo</FieldLabel>

                <Input
                  id="group-name"
                  type="text"
                  placeholder="Ej: Salsa"
                  value={draft.name}
                  onChange={(e) =>
                    setDraft((prev) => ({ ...prev, name: e.target.value }))
                  }
                />
              </Field>

              <Field>
                <FieldLabel htmlFor="group-options">Opciones</FieldLabel>

                <Textarea
                  id="group-options"
                  spellCheck={false}
                  placeholder="Ej: Boloñesa, Caruso, 4 quesos"
                  value={draft.options}
                  onChange={(e) =>
                    setDraft((prev) => ({ ...prev, options: e.target.value }))
                  }
                />

                <FieldDescription>
                  Ingresá las opciones separadas por coma.
                </FieldDescription>

                {hasDuplicateOptions && (
                  <p className="text-destructive text-sm">
                    No se permiten opciones repetidas.
                  </p>
                )}
              </Field>

              <Field>
                <FieldLabel>
                  ¿Cuántas opciones pueden elegir a la vez?
                </FieldLabel>

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

            <DialogFooter>
              <Button
                type="button"
                variant="outline"
                onClick={() => setGroupDialogOpen(false)}
              >
                Cancelar
              </Button>

              <Button
                type="button"
                disabled={!canSaveDraft}
                onClick={saveDraft}
              >
                {editingIndex === null ? "Agregar" : "Guardar"}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>

        {menu ? (
          <div className="mt-8 flex justify-end gap-3">
            <Button type="button" variant="outline" asChild>
              <Link href={menusRoutes.index().url}>Cancelar</Link>
            </Button>

            <Button type="submit" disabled={processing}>
              {processing ? "Guardando..." : "Modificar"}
            </Button>
          </div>
        ) : (
          <Button type="submit" className="mt-4 w-full" disabled={processing}>
            {processing ? "Creando..." : "Crear"}
          </Button>
        )}
      </form>

      {menu && (
        <Sheet
          open={saveSheetOpen}
          onOpenChange={(open) => {
            setSaveSheetOpen(open)

            if (!open) {
              setSaveSheetStage("confirm")
            }
          }}
        >
          <SheetContent
            side="bottom"
            showCloseButton={false}
            className="mx-auto gap-0 rounded-t-3xl pb-[env(safe-area-inset-bottom)] md:max-w-xl"
          >
            <div className="bg-muted-foreground/30 mx-auto mt-3 h-1 w-10 rounded-full" />

            {saveSheetStage === "confirm" ? (
              <>
                <SheetHeader className="items-start px-6 pt-8 text-left">
                  <SheetTitle className="text-base">
                    ¿Modificar el plato guardado?
                  </SheetTitle>

                  <SheetDescription className="text-base">
                    Este plato se modificará en tus platos guardados.
                  </SheetDescription>
                </SheetHeader>

                <SheetFooter className="flex-row gap-3 px-6 pt-6 pb-6">
                  <Button
                    type="button"
                    variant="secondary"
                    className="h-11 flex-1"
                    onClick={() => setSaveSheetOpen(false)}
                    disabled={processing}
                  >
                    Volver
                  </Button>

                  <Button
                    type="button"
                    className="h-11 flex-1"
                    onClick={applyChanges}
                    disabled={processing}
                  >
                    {processing ? "Aplicando..." : "Aplicar cambios"}
                  </Button>
                </SheetFooter>
              </>
            ) : (
              <>
                <SheetHeader className="items-start px-6 pt-8 text-left">
                  <SheetTitle className="text-base">
                    ¡Plato modificado!
                  </SheetTitle>

                  <SheetDescription className="text-base">
                    Tu plato fue modificado correctamente.
                  </SheetDescription>
                </SheetHeader>

                <SheetFooter className="px-6 pt-6 pb-6">
                  <Button type="button" className="h-11 w-full" asChild>
                    <Link href={menusRoutes.index().url}>Listo</Link>
                  </Button>
                </SheetFooter>
              </>
            )}
          </SheetContent>
        </Sheet>
      )}
    </>
  )
}
