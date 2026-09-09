import { Head } from "@inertiajs/react"

import NewMenuForm from "@/components/menus/new-menu-form"
import { Card, CardTitle } from "@/components/ui/card"

export default function New() {
  return (
    <div className="m-4">
      <Head title="Crear plato" />

      <Card className="mx-auto w-100 p-4">
        <CardTitle> Crear plato </CardTitle>
        <NewMenuForm
          formSuccess={() => {
            /* En principio no es necesario hacer nada acá */
          }}
        />
      </Card>
    </div>
  )
}
