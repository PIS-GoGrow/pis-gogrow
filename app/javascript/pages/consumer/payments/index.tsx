import { Head } from "@inertiajs/react"
import { Receipt } from "lucide-react"

import { Badge } from "@/components/ui/badge"
import AppLayout from "@/layouts/app-layout"
import type { BreadcrumbItem } from "@/types"

// Definimos la interfaz de los datos que nos manda el mock del controlador
interface Payment {
  id: number
  date: string
  provider_name: string
  amount: number
  status: "pending" | "accepted" | "rejected"
  rejection_reason?: string
}

interface Props {
  payments: Payment[]
}

export default function Index({ payments }: Props) {
  const breadcrumbs: BreadcrumbItem[] = [
    { title: "Historial de Pagos", href: "/employee/payments" },
  ]

  // Función auxiliar para renderizar el badge correcto según el estado
  const renderStatus = (status: Payment["status"]) => {
    switch (status) {
      case "accepted":
        return <Badge className="bg-green-100 text-green-700 hover:bg-green-200">Aceptado</Badge>
      case "rejected":
        return <Badge variant="destructive">Rechazado</Badge>
      default:
        return <Badge className="bg-yellow-100 text-yellow-700 hover:bg-yellow-200">Pendiente</Badge>
    }
  }

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title="Mis Pagos" />

      <div className="mx-auto flex w-full max-w-5xl flex-col gap-6 p-5">
        <div>
          <h1 className="text-2xl font-bold">Mis Pagos</h1>
          <p className="text-sm text-muted-foreground">
            Historial de pagos realizados a los proveedores.
          </p>
        </div>

        {payments.length === 0 ? (
          <div className="flex flex-col items-center justify-center rounded-xl border border-dashed py-12">
            <Receipt className="mb-4 size-12 text-muted-foreground/50" />
            <p className="text-sm text-muted-foreground">Aún no has registrado ningún pago.</p>
          </div>
        ) : (
          <div className="rounded-xl border bg-card">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead className="border-b bg-muted/50 text-muted-foreground">
                  <tr>
                    <th className="px-4 py-3 font-medium">Fecha</th>
                    <th className="px-4 py-3 font-medium">Proveedor</th>
                    <th className="px-4 py-3 font-medium text-right">Monto</th>
                    <th className="px-4 py-3 font-medium">Estado del comprobante</th>
                  </tr>
                </thead>
                <tbody className="divide-y">
                  {payments.map((payment) => (
                    <tr key={payment.id} className="hover:bg-muted/50">
                      <td className="px-4 py-3">{payment.date}</td>
                      <td className="px-4 py-3 font-medium">{payment.provider_name}</td>
                      <td className="px-4 py-3 text-right">${payment.amount}</td>
                      <td className="px-4 py-3">
                        <div className="flex flex-col items-start gap-1">
                          {renderStatus(payment.status)}
                          {payment.status === "rejected" && payment.rejection_reason && (
                            <span className="text-xs text-destructive">
                              {payment.rejection_reason}
                            </span>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>
    </AppLayout>
  )
}