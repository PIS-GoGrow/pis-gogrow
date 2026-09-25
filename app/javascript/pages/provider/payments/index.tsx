import { Head, router } from "@inertiajs/react"
import { Check, Eye, X } from "lucide-react"
import { useState } from "react"

import ReceiptSheet from "@/components/payments/receipt-sheet"
import RejectPaymentDialog from "@/components/payments/reject-payment-dialog"
import { Button } from "@/components/ui/button"
import { DialogTrigger } from "@/components/ui/dialog"
import { SheetTrigger } from "@/components/ui/sheet"
import AppLayout from "@/layouts/app-layout"
import { providerPayments } from "@/routes"
import type { BreadcrumbItem } from "@/types"
import type { ProviderPayment } from "@/types/serializers/ProviderPayment"

interface Props {
  payments: ProviderPayment[]
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
          <p className="text-muted-foreground text-sm">
            Revisa y aprueba los pagos reportados por los empleados.
          </p>
        </div>

        {payments.length === 0 ? (
          <div className="flex flex-col items-center justify-center rounded-xl border border-dashed py-12">
            <p className="text-muted-foreground text-sm">
              No hay comprobantes pendientes de revisión.
            </p>
          </div>
        ) : (
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {payments.map((payment) => (
              <div
                key={payment.id}
                className="bg-card flex flex-col gap-4 rounded-xl border p-5"
              >
                <div className="flex items-center justify-between">
                  <p className="font-semibold">{payment.employee_name}</p>
                  <p className="text-muted-foreground text-sm">
                    {payment.date}
                  </p>
                </div>

                <div className="flex items-end justify-between">
                  <div>
                    <p className="text-muted-foreground text-xs tracking-wider uppercase">
                      Monto
                    </p>
                    <p className="text-xl font-bold">${payment.amount}</p>
                  </div>

                  {payment.receipt_url && (
                    <ReceiptSheet
                      receiptUrl={payment.receipt_url}
                      contentType={payment.receipt_content_type}
                      filename={payment.employee_name}
                    >
                      <SheetTrigger asChild>
                        <Button variant="outline" size="sm">
                          <Eye className="mr-2 size-4" />
                          Ver comprobante
                        </Button>
                      </SheetTrigger>
                    </ReceiptSheet>
                  )}
                </div>

                <div className="mt-2 flex gap-2 border-t pt-4">
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
                    className="hover:bg-accent hover:text-accent-foreground flex-1 bg-white text-black"
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
