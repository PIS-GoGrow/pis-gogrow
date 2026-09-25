# frozen_string_literal: true

class Consumer::OrdersController < Consumer::InertiaController
  def index
    orders = Current.user.consumer.orders.preload(schedule: { menu: { provider: :user } })

    @upcoming_orders = orders.upcoming
    @past_orders = orders.history
  end

  def show
    # El find va sobre las órdenes del empleado y no sobre Order: pedir la de otro
    # tiene que ser un 404, no una página ajena.
    @order = Current.user.consumer.orders.preload(schedule: { menu: { provider: :user } }).find(params[:id])
  end

  def create
    consumer = Current.user.consumer
    requested_items = order_params.fetch(:items)

    # Rechazamos si no hay carrito o si las cantidades no son numéricas.
    return reject_order(:empty_cart) if requested_items.empty?
    return reject_order(:invalid_quantity) unless requested_items.all? { |item| item[:quantity].to_s.match?(/\A[1-9]\d*\z/) }
    # Rechazamos si la dirección es invalida
    # delivery_addresses ya verifica que la dirección no sea blank, por lo que acá
    # está manejado el caso de que no haya dirección de envío.
    return reject_order(:invalid_address) unless consumer.delivery_addresses.include?(order_params[:address])

    created_orders = []

    Order.transaction do
      consumer.lock!

      benefit_percentage = consumer.current_benefit&.percentage.to_i
      remaining_subsidized = benefit_percentage.positive? ? consumer.remaining_subsidized_meals : 0

      # Obtenemos las ids de los schedules para los que se hicieron órdenes y traemos todos
      # los schedules correspondientes.
      schedule_ids = requested_items.pluck(:schedule_id).uniq
      schedules = Schedule.includes(menu: :provider).where(id: schedule_ids, date: allowed_dates).order(:id).lock.index_by(&:id)

      # Tiramos error si alguno de los schedules no existen o si están fuera del rango de fechas permitidas
      raise ActiveRecord::RecordNotFound unless schedules.size == schedule_ids.size

      requested_items.each do |item|
        quantity = item[:quantity].to_i

        subsidized_quantity = [
          quantity,
          remaining_subsidized
        ].min

        schedule = schedules.fetch(item[:schedule_id].to_i)

        # Elegimos el modo de entrega. Si el usuario eligió entrega a domicilio, pero
        # el proveedor solo hace entregas a oficina, se cambia automáticamente para que se
        # entregue en la oficina. En el carrito ya se le avisó al consumidor que la entrega
        # se iba a hacer en la oficina.
        delivery = consumer.delivery_for(schedule.menu.provider, order_params[:address])

        # Si en este punto la dirección es blank, es porque no hay una dirección para la
        # empresa.
        if delivery[:address].blank?
          reject_order(:office_address_required)
          raise ActiveRecord::Rollback
        end

        # Tratamos de crear la orden
        order = Order.reserve(
          consumer:,
          schedule:,
          quantity:,
          notes: item[:notes],
          discount_percentage: benefit_percentage,
          subsidized_quantity:,
          **delivery
        )
        raise ActiveRecord::RecordInvalid, order unless order.persisted?

        remaining_subsidized -= subsidized_quantity
        created_orders << order
      end
    end

    redirect_to dashboard_confirmation_path(confirmed_order_ids: created_orders.map(&:id)), notice: t("flash.cart_confirmed"), status: :see_other unless performed?
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound, KeyError
    reject_order(:cart_unavailable)
  end

  def cancel
    order = Current.user.consumer.orders.find(params[:id])

    if order.cancel(by: Current.user)
      redirect_to orders_path, notice: t("flash.order_cancelled"), status: :see_other
    else
      redirect_to orders_path, alert: t("validations.order_not_cancellable"), status: :see_other
    end
  end

  private

  def reject_order(reason)
    redirect_to dashboard_path, inertia: {
      errors: { order_error: t("validations.#{reason}") }
    }, status: :see_other
  end

  # Permitir hacer pedidos entre hoy y el viernes siguiente.
  def allowed_dates
    Date.current..Date.current.next_week(:friday)
  end

  def order_params
    params.expect(order: [ :address, items: [ [ :schedule_id, :quantity, :notes ] ] ])
  end
end
