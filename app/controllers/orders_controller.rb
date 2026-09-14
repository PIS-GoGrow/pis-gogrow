# frozen_string_literal: true

class OrdersController < InertiaController
  # Antes de ejecutar create, exige un perfil de empleado (Consumer).
  # La clase base ya comprueba que exista una sesión iniciada.
  before_action :authenticate_consumer

  # Acción que Rails ejecuta al recibir POST /orders.
  def create
    # Solo acepta la oferta elegida y una nota opcional dentro de "order".
    # El navegador no puede decidir el empleado, precio, cantidad ni estado.
    attributes = params.expect(order: [ :schedule_id, :notes ])
    # Schedule es un plato ofrecido para una fecha; find devuelve 404 si no existe.
    schedule = Schedule.find(attributes[:schedule_id])
    # Current.user es la cuenta de la sesión. Su consumer es el perfil de empleado.
    # El modelo Order se encarga de comprobar el cupo y guardar la reserva.
    order = Order.reserve(consumer: Current.user.consumer, schedule: schedule, notes: attributes[:notes])

    # persisted? indica si el pedido quedó guardado en la base de datos.
    if order.persisted?
      # Vuelve a la página de origen, o al dashboard si no hay origen.
      # t busca el mensaje en las traducciones; 303 indica continuar con un GET.
      redirect_back_or_to dashboard_path, notice: t("flash.order_created"), status: :see_other
    else
      # Devuelve los errores mediante Inertia para que el formulario los muestre.
      redirect_back_or_to dashboard_path, inertia: { errors: order.errors }, status: :see_other
    end
  end

  private

  def authenticate_consumer
    # Una cuenta sin perfil de empleado recibe 403 (acceso prohibido).
    head :forbidden unless Current.user.consumer
  end
end
