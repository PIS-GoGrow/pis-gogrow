import { Head, Link, Form } from '@inertiajs/react'
import { menus as menusRoutes } from "@/routes"

export default function New() {
  return (
    <div>
			<Head title="Agregar plato" />
      <h1>Agregar plato</h1>
			<Form action="/menus" method="post">
				<input type="name" name="name" /> <br />
				<input type="price" name="price" /> <br />
				<input type="description" name="description" /> <br />
				<button type="submit">Crear</button>
			</Form>
    </div>
  );
}
