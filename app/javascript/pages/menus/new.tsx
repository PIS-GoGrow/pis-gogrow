import { Head, Link, useForm } from '@inertiajs/react'
import { menus as menusRoutes } from "@/routes"
import { Button } from "@/components/ui/button"
import {
  Card,
  CardAction,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import {
  Field,
  FieldDescription,
  FieldLabel,
} from "@/components/ui/field"
import { Label } from "@/components/ui/label"
import { useState } from 'react'

export function NewForm({ onCancelar }) {
  const [priceError, setPriceError] = useState(false);

  const { data, setData, post, processing, errors, setError, clearErrors } = useForm({
    name: '',
    description: '',
    price: ''
  })

  function handlePriceChange(e) {
    const valor = e.target.value
    setData('price', valor)

    if (valor !== '' && (isNaN(Number(valor)) || Number(valor) <= 0)) {
      setError('price', 'El precio debe ser un número mayor a 0.')
      setPriceError(true)
    } else {
      clearErrors('price')
      setPriceError(false)
    }
  }

  function handleSubmit(e) {
    e.preventDefault()
		if (data.name === '')
				setError('name', 'No puede estar vacío.');
    else if (data.price === '')
        setError('price', 'No puede estar vacío.');
		else 
				post(menusRoutes.create());
  }

  return (
    <form onSubmit={handleSubmit}>
      <div className="flex flex-col gap-3">
        <div className="grid gap-2">
          <Field data-invalid={errors.name != undefined && errors.name !== ''}>
            <FieldLabel htmlFor="name">Nombre</FieldLabel>
                <Input
                  type="text"
                  name="name"
                  value={data.name}
                  onChange={(e) => {
                    setData('name', e.target.value);
                    clearErrors('name')
                  }}
                />
						    {errors.name && (
                  <FieldDescription>
                    {errors.name}
                  </FieldDescription>
                )}
              </Field>
            </div>
            <div className="grid gap-2">
              <Field data-invalid={errors.description != undefined && errors.description !== ''}>
                <FieldLabel htmlFor="description">Descripción</FieldLabel>
                <Input
                  type="text"
                  name="description"
                  value={data.description}
                  onChange={(e) => setData('description', e.target.value)}
								/>
								{errors.description && (
                  <FieldDescription>
											{errors.description}
                  </FieldDescription>
                )}
              </Field>
            </div>
            <div className="grid gap-2">
              <Field data-invalid={errors.price != undefined && errors.price !== ''}>
                <FieldLabel htmlFor="price">Precio</FieldLabel>
                <Input
                  type="text"
                  name="price"
                  value={data.price}
                  onChange={(e) => handlePriceChange(e)}
                />
                {errors.price && (
                  <FieldDescription>
										{errors.price}
								  </FieldDescription>
                )}
              </Field>
            </div>
          </div>
          <Button type="submit" className="mt-4 w-full" disabled={priceError || processing}>
            {processing ? 'Creando...' : 'Crear'}
          </Button>
      </form>
  );
}

export default function New() {
  return (
    <div className="m-4">
			<Head title="Crear plato" />
			
		  <NewForm />
    </div>
  );
}
