# frozen_string_literal: true

class Consumer::OrdersController < Consumer::InertiaController
  def index
    consumer = Current.user.consumer
    orders = consumer.orders.preload(schedule: { menu: { provider: :user } })

    @upcoming_orders = orders.upcoming
    @past_orders = orders.history.where(created_at: (Date.current - 3.months)..)

    @providers = (@upcoming_orders + @past_orders)
      .map { |order| order.schedule.menu.provider }
      .uniq
  end

  def show
    consumer = Current.user.consumer
    # El find va sobre las órdenes del empleado y no sobre Order: pedir la de otro
    # tiene que ser un 404, no una página ajena.
    @order = consumer.orders.preload(schedule: { menu: { provider: :user } }).find(params[:id])
    @delivery_addresses = @order.delivery_address_options consumer
    @max_quantity = @order.max_quantity
    @editing = params[:edit] == "1"
  end

  def create
    consumer = Current.user.consumer
    requested_items = order_params.fetch(:items)
    benefit_percentage = consumer&.current_monthly_benefit&.percentage.to_i

    # Rechazamos si no hay carrito o si las cantidades no son numéricas.
    return reject_order(:empty_cart) if requested_items.empty?
    return reject_order(:invalid_quantity) unless requested_items.all? { |item| item[:quantity].to_s.match?(/\A[1-9]\d*\z/) }
    # Rechazamos si la dirección es invalida
    # delivery_addresses ya verifica que la dirección no sea blank, por lo que acá
    # está manejado el caso de que no haya dirección de envío.
    return reject_order(:invalid_address) unless consumer.delivery_addresses.include?(order_params[:address]) || valid_new_address?(consumer, order_params[:address])

    created_orders = []

    Order.transaction do
      consumer.lock!

      remaining_subsidized =
        benefit_percentage.positive? ? consumer.remaining_monthly_benefit : 0
      schedule_ids = requested_items.pluck(:schedule_id)

      # Obtenemos las ids de los schedules para los que se hicieron órdenes y traemos todos
      # los schedules correspondientes.
      schedules = Schedule.includes(menu: :provider).where(id: schedule_ids.uniq, date: allowed_dates).order(:id).lock.index_by(&:id)

      # Tiramos error si alguno de los schedules no existen o si están fuera del rango de fechas permitidas
      raise ActiveRecord::RecordNotFound unless schedules.size == schedule_ids.uniq.size

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
          benefits: [ consumer.current_monthly_benefit ].compact,
          **delivery
        )

        raise ActiveRecord::RecordInvalid, order unless order.persisted?

        remaining_subsidized -= subsidized_quantity
        created_orders << order
      end
    end

    redirect_to dashboard_confirmation_path(confirmed_order_ids: created_orders.map(&:id)), notice: t("flash.cart_confirmed"), status: :see_other unless performed?
  rescue ActiveRecord::RecordInvalid => error
    reject_order(order_error_reason(error.record))
  rescue ActiveRecord::RecordNotFound, KeyError
    reject_order(:cart_unavailable)
  end

  def update
    consumer = Current.user.consumer
    order = consumer.orders.find(params[:id])

    return reject_update(order, :invalid_quantity) unless update_params[:quantity].to_s.match?(/\A[1-9]\d*\z/)
    return reject_update(order, :invalid_address) unless delivery_address_options(consumer, order).pluck(:address).include?(update_params[:address])

    delivery = consumer.delivery_for(order.provider, update_params[:address])
    return reject_update(order, :office_address_required) if delivery[:address].blank?

    benefit_percentage = consumer&.current_monthly_benefit&.percentage.to_i
    modified = order.modify(
      by: Current.user,
      quantity: update_params[:quantity].to_i,
      notes: update_params[:notes],
      delivery:,
      discount_percentage: benefit_percentage,
      remaining_subsidized: benefit_percentage.positive? ? consumer.remaining_monthly_benefit : 0
    )

    if modified
      redirect_to order_path(order), notice: t("flash.order_updated"), status: :see_other
    else
      redirect_to order_path(order),
                  alert: order.errors.full_messages.first || t("validations.order_not_modifiable"),
                  status: :see_other
    end
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

  def reject_update(order, reason)
    redirect_to order_path(order), alert: t("validations.#{reason}"), status: :see_other
  end

  def reject_order(reason)
    redirect_to dashboard_path, inertia: {
      errors: { order_error: t("validations.#{reason}") }
    }, status: :see_other
  end

  # Permitir hacer pedidos entre hoy y el viernes siguiente.
  def allowed_dates
    Date.current..Date.current.next_week(:friday)
  end

  def order_error_reason(order)
    return :order_deadline_passed if order.errors[:schedule_id].include?(t("validations.order_deadline_passed"))

    schedule = order.schedule

    return :schedule_unavailable if schedule && !schedule.available
    return :insufficient_stock if schedule && schedule.remaining_amount < order.amount.to_i

    :cart_unavailable
  end

  # Además de las direcciones conocidas, el carrito puede mandar una que el
  # empleado ingresó sin guardarla para futuros pedidos.
  def valid_new_address?(consumer, address)
    consumer.delivery_address_options.pluck(:address).include?(address) || DeliveryAddress.valid_full_address?(address)
  end

  def update_params
    params.expect(order: [ :quantity, :address, :notes ])
  end

  def order_params
    params.expect(order: [ :address, items: [ [ :schedule_id, :quantity, :notes ] ] ])
  end
end
