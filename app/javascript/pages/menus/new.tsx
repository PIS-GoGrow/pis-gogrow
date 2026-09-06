import { Head, Link, Form } from '@inertiajs/react'
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
import { Label } from "@/components/ui/label"

export function NewForm({ onCancelar }) {
		return(
		  <Card className="mx-auto w-full max-w-sm">
        <CardHeader>
          <CardTitle>Crear plato</CardTitle>
        </CardHeader>
				<Form action="/menus" method="post">
          <CardContent>
            <div className="flex flex-col gap-3">
              <div className="grid gap-2">
						    <Label htmlFor="name">Nombre</Label>
				        <Input type="name" name="name" /> <br />
							</div>

              <div className="grid gap-2">
						    <Label htmlFor="description">Descripción</Label>
				        <Input type="description" name="description" /> <br />
							</div>

              <div className="grid gap-2">
						    <Label htmlFor="price">Precio</Label>
				        <Input type="price" name="price" /> <br />
							</div>
					  </div>
		      </CardContent>
		      <CardFooter className="flex-col gap-2">
					  <Button type="submit" className="w-full"> Crear </Button>
					  <Button onClick={() => { onCancelar(); }} variant="outline" className="w-full"> Cancelar </Button>
          </CardFooter>
		    </Form>
      </Card>
		)
}

export default function New() {
  return (
    <div>
			<Head title="Agregar plato" />
			
		  <h1>Agregar plato</h1>
		  <NewForm />
    </div>
  );
}
