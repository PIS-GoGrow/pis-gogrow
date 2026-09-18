class Consumer::PaymentsController < InertiaController

  def index
    # Lógica estatica para mostrar los pagos de los consumidores
    # Hasta que este hecho IBP-019
    mock_payments = [
      { id: 1, date: "2026-09-15", provider_name: "TuViandita", amount: 1500, status: "accepted" },
      { id: 2, date: "2026-09-16", provider_name: "EndulzateByNoe", amount: 2600, status: "pending" }
    ]
    render inertia: 'consumer/payments/index', props: { payments: mock_payments }
  end
end