import { useForm } from "@inertiajs/react"

import { Button } from "@/components/ui/button"
import { Field, FieldDescription, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { providerMenus as menusRoutes } from "@/routes"

interface NewMenuProps {
  formSuccess: () => void
}

export default function NewMenuForm({ formSuccess }: NewMenuProps) {
  const {
    data,
    setData,
    post,
    processing,
    errors,
    setError,
    clearErrors,
    transform,
  } = useForm({
    name: "",
    description: "",
    price: "",
    fillings: "",
    sauces: "",
  })

  function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault()

    // No validamos que exista descripción porque no se requiere
    if (data.name === "") setError("name", ["No puede estar vacío."])
    else if (data.price === "") setError("price", ["No puede estar vacío."])
    else {
      transform((data) => ({
        menu: {
          ...data,
          fillings: optionsFrom(data.fillings),
          sauces: optionsFrom(data.sauces),
        },
      }))
      post(menusRoutes.create().url, {
        onSuccess: () => {
          formSuccess()
        },
      })
    }
  }

  return (
    <form onSubmit={handleSubmit}>
      <div className="flex flex-col gap-3">
        <div className="grid gap-2">
          <Field data-invalid={!!errors.name?.length}>
            <FieldLabel htmlFor="name">Nombre</FieldLabel>
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
        </div>
        <div className="grid gap-2">
          <Field data-invalid={!!errors.description?.length}>
            <FieldLabel htmlFor="description">Descripción</FieldLabel>
            <Input
              type="text"
              name="description"
              value={data.description}
              onChange={(e) => setData("description", e.target.value)}
            />
            {!!errors.description?.length && (
              <FieldDescription>{errors.description}</FieldDescription>
            )}
          </Field>
        </div>
        <div className="grid gap-2">
          <Field data-invalid={!!errors.price?.length}>
            <FieldLabel htmlFor="price">Precio</FieldLabel>
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
        </div>
        <div className="grid gap-2">
          <Field>
            <FieldLabel htmlFor="fillings">Rellenos disponibles</FieldLabel>
            <Input
              type="text"
              name="fillings"
              value={data.fillings}
              onChange={(e) => setData("fillings", e.target.value)}
              placeholder="Ricota y nuez, Ricota y espinaca"
            />
            <FieldDescription>
              Separalos con comas. Dejalo vacío si no aplica.
            </FieldDescription>
          </Field>
        </div>
        <div className="grid gap-2">
          <Field>
            <FieldLabel htmlFor="sauces">Salsas disponibles</FieldLabel>
            <Input
              type="text"
              name="sauces"
              value={data.sauces}
              onChange={(e) => setData("sauces", e.target.value)}
              placeholder="Filetto, Bolognesa"
            />
            <FieldDescription>
              Separalas con comas. Dejalo vacío si no aplica.
            </FieldDescription>
          </Field>
        </div>
      </div>
      <Button type="submit" className="mt-4 w-full" disabled={processing}>
        {processing ? "Creando..." : "Crear"}
      </Button>
    </form>
  )
}

function optionsFrom(value: string) {
  return value
    .split(",")
    .map((option) => option.trim())
    .filter(Boolean)
}
