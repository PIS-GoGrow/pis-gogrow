import { Head } from '@inertiajs/react'

import NewMenuForm from '@/components/new-menu-form'


export default function New() {
  return (
    <div className="m-4">
			<Head title="Crear plato" />
			
		  <NewMenuForm />
    </div>
  );
}
