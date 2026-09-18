class Provider::PaymentsController < InertiaController

  def index
    # Lógica estatica para mostrar los pagos de los proveedores
    # Hasta que este hecho IBP-019
    mock_payments = [
      { id: 1, date: "2026-09-15", consumer_name: "Juan Pérez", amount: 1500, status: "accepted" }
    ]
    render inertia: 'provider/payments/index', props: { payments: mock_payments }
  end

   def update
     payment = Payment.find(params[:id])
     payment.update!(status: params[:status], rejection_reason: params[:rejection_reason])
     redirect_to provider_payments_path
   end
end