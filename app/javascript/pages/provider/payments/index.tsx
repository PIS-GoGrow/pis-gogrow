import { useState } from "react"
import { Head, router } from "@inertiajs/react"
import { Check, Eye, X } from "lucide-react"

import { Button } from "@/components/ui/button"
import { DialogTrigger } from "@/components/ui/dialog"
import RejectPaymentDialog from "@/components/payments/reject-payment-dialog"
import AppLayout from "@/layouts/app-layout"
import type { BreadcrumbItem } from "@/types"
import { providerPayments } from "@/routes"

interface Payment {
  id: number
  date: string
  employee_name: string
  amount: number
  status: string
  file_url: string
}

interface Props {
  payments: Payment[]
}

export default function Index({ payments }: Props) {
  const [processingId, setProcessingId] = useState<number | null>(null)

  const breadcrumbs: BreadcrumbItem[] = [
    { title: "Revisar Comprobantes", href: providerPayments.index().url },
  ]

  const handleApprove = (id: number) => {
  setProcessingId(id)

  router.patch(
    providerPayments.update(id).url,
    { status: "approved" },
    {
      preserveScroll: true,
      onFinish: () => setProcessingId(null),
    },
  )
}

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title="Revisar Comprobantes" />

      <div className="mx-auto flex w-full max-w-5xl flex-col gap-6 p-5">
        <div>
          <h1 className="text-2xl font-bold">Comprobantes Pendientes</h1>
          <p className="text-sm text-muted-foreground">
            Revisa y aprueba los pagos reportados por los empleados.
          </p>
        </div>

        {payments.length === 0 ? (
          <div className="flex flex-col items-center justify-center rounded-xl border border-dashed py-12">
            <p className="text-sm text-muted-foreground">No hay comprobantes pendientes de revisión.</p>
          </div>
        ) : (
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {payments.map((payment) => (
              <div key={payment.id} className="flex flex-col gap-4 rounded-xl border bg-card p-5">
                <div className="flex items-center justify-between">
                  <p className="font-semibold">{payment.employee_name}</p>
                  <p className="text-sm text-muted-foreground">{payment.date}</p>
                </div>
                
                <div className="flex items-end justify-between">
                  <div>
                    <p className="text-xs text-muted-foreground uppercase tracking-wider">Monto</p>
                    <p className="text-xl font-bold">${payment.amount}</p>
                  </div>
                  
                  {/* Botón para ver imagen (abre en otra pestaña) */}
                  {payment.file_url && (
                    <Button variant="outline" size="sm" asChild>
                      <a href={payment.file_url} target="_blank" rel="noopener noreferrer">
                        <Eye className="mr-2 size-4" />
                        Ver imagen
                      </a>
                    </Button>
                  )}
                </div>

                <div className="mt-2 flex gap-2 pt-4 border-t">
                    <RejectPaymentDialog paymentId={payment.id}>
                    <DialogTrigger asChild>
                        <Button 
                          className="flex-1 bg-black text-white hover:bg-black/90" 
                          size="sm"
                        >
                          <X className="mr-2 size-4" />
                          Rechazar
                        </Button>
                    </DialogTrigger>
                    </RejectPaymentDialog>
                  
                  <Button 
                    variant="outline"
                    className="flex-1 bg-white text-black hover:bg-accent hover:text-accent-foreground"
                    size="sm"
                    disabled={processingId === payment.id}
                    onClick={() => handleApprove(payment.id)}
                  >
                    <Check className="mr-2 size-4" />
                    Aprobar
                  </Button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </AppLayout>
  )
}