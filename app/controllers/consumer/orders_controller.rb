# frozen_string_literal: true

class Consumer::OrdersController < Consumer::InertiaController
  before_action :set_consumer

  def index
    orders = @consumer.orders.preload(provider: :user, schedule: { menu: { provider: :user } })

    @upcoming_orders = orders.upcoming
    @past_orders = orders.history.where(created_at: (Date.current - 3.months)..)

    @providers = (@upcoming_orders + @past_orders)
      .map(&:provider)
      .compact_blank
      .uniq
  end

  def show
    # El find va sobre las órdenes del empleado y no sobre Order: pedir la de otro
    # tiene que ser un 404, no una página ajena.
    @order = @consumer.orders.preload(
      schedule: { menu: [ :option_groups, { provider: :user } ] }
    ).find(params[:id])

    @delivery_addresses = @order.delivery_address_options @consumer
    @max_quantity = @order.max_quantity
    @editing = params[:edit] == "1"

    @option_groups = @order.schedule&.menu&.option_groups.to_a.map do |group|
      {
        id: group.id,
        name: group.name,
        options: group.options,
        limit: group.limit,
        required: group.required
      }
    end
  end

  def create
    requested_items = order_params.fetch(:items)

    # Rechazamos si no hay carrito o si las cantidades no son numéricas.
    return reject_order(:empty_cart) if requested_items.empty?
    return reject_order(:invalid_quantity) unless requested_items.all? { |item| item[:quantity].to_s.match?(/\A[1-9]\d*\z/) }
    # Rechazamos si la dirección es invalida
    # delivery_addresses ya verifica que la dirección no sea blank, por lo que acá
    # está manejado el caso de que no haya dirección de envío.
    return reject_order(:invalid_address) unless @consumer.delivery_addresses.include?(order_params[:address]) || valid_new_address?(@consumer, order_params[:address])

    created_orders = []

    Order.transaction do
      @consumer.lock!

      schedule_ids = requested_items.pluck(:schedule_id)

      # Obtenemos las ids de los schedules para los que se hicieron órdenes y traemos
      # todos los schedules correspondientes.
      schedules =
        Schedule
          .includes(menu: :provider)
          .where(id: schedule_ids.uniq, date: Calendar.new.allowed_order_dates)
          .order(:id)
          .lock.index_by(&:id)

      # Tiramos error si alguno de los schedules no existen o si están fuera del
      # rango de fechas permitidas (definidas por Calendar#allowed_order_dates)
      raise ActiveRecord::RecordNotFound unless schedules.size == schedule_ids.uniq.size

      pricing = OrderPricing.new(@consumer).call(
        requested_items.map { |item| { schedule: schedules.fetch(item[:schedule_id].to_i), quantity: item[:quantity].to_i } }
      )

      requested_items.each do |item|
        quantity = item[:quantity].to_i
        schedule = schedules.fetch(item[:schedule_id].to_i)

        # Elegimos el modo de entrega. Si el usuario eligió entrega a domicilio, pero
        # el proveedor solo hace entregas a oficina, se cambia automáticamente para que se
        # entregue en la oficina. En el carrito ya se le avisó al consumidor que la entrega
        # se iba a hacer en la oficina.
        delivery = @consumer.delivery_for(schedule.menu.provider, order_params[:address])

        # Si en este punto la dirección es blank, es porque no hay una dirección para la
        # empresa.
        if delivery[:address].blank?
          reject_order(:office_address_required)
          raise ActiveRecord::Rollback
        end

        # Tratamos de crear la orden
        order = Order.reserve(
          consumer: @consumer,
          schedule:,
          quantity:,
          notes: item[:notes],
          discounted_price: pricing[schedule.id].discounted_price,
          selected_options: selected_options_for(schedule.menu, item[:options]),
          benefits: pricing[schedule.id].benefits,
          **delivery
        )

        raise ActiveRecord::RecordInvalid, order unless order.persisted?

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
    order = @consumer.orders.find(params[:id])

    return reject_update(order, :invalid_quantity) unless update_params[:quantity].to_s.match?(/\A[1-9]\d*\z/)
    return reject_update(order, :invalid_address) unless order.delivery_address_options(@consumer).pluck(:address).include?(update_params[:address])

    delivery = @consumer.delivery_for(order.provider, update_params[:address])
    return reject_update(order, :office_address_required) if delivery[:address].blank?

    modified = order.modify(
      by: Current.user,
      quantity: update_params[:quantity].to_i,
      notes: update_params[:notes],
      delivery:,
      selected_options: selected_options_for(order.schedule&.menu, update_params[:options])
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
    order = @consumer.orders.find(params[:id])

    if order.cancel(by: Current.user)
      redirect_to orders_path, notice: t("flash.order_cancelled"), status: :see_other
    else
      redirect_to orders_path, alert: t("validations.order_not_cancellable"), status: :see_other
    end
  end

  def pricing
    requested_items = pricing_params

    # Obtenemos las ids de los schedules para los que se hicieron órdenes y traemos
    # todos los schedules correspondientes.
    schedule_ids = requested_items.pluck(:schedule_id)
    schedules =
      Schedule
        .includes(menu: :provider)
        .where(id: schedule_ids.uniq, date: Calendar.new.allowed_order_dates)
        .order(:id)
        .index_by(&:id)

    requested_items.map! do |item|
      schedule = schedules.dig(item[:schedule_id].to_i)
      { schedule: , quantity: item[:quantity].to_i } if schedule
    end.compact!

    @pricing = OrderPricing.new(@consumer).call(requested_items)

    render json: to_pricing(requested_items, @pricing)
  end

  private

  def to_pricing(items, pricing)
    items_by_schedule = items.index_by { |item| item[:schedule].id }

    lines = pricing.to_h do |schedule_id, result|
      item = items_by_schedule.fetch(schedule_id)
      quantity = item[:quantity]
      price = result.price.to_f

      tiers = result.benefits.map do |benefit, units_used|
        discount = price * units_used * benefit.percentage / 100 / quantity

        {
          name: benefit.benefit_configuration.name,
          percentage: benefit.percentage,
          quantity: units_used,
          discount: discount.to_f
        }
      end

      discount = price - result.discounted_price.to_f
      [
        schedule_id.to_s,
        {
          subtotal: price,
          discount: discount,
          total: price - discount,
          tiers: tiers
        }
      ]
    end

    {
      subtotal: lines.values.sum { |line| line[:subtotal] },
      discount: lines.values.sum { |line| line[:discount] },
      total: lines.values.sum { |line| line[:total] },
      lines: lines,
      subsidizedQuantity: items.sum do |item|
        pricing.fetch(item[:schedule][:id]).benefits.sum { |_, u| u }
      end,
      fullPriceQuantity: items.sum do |item|
        schedule_id = item[:schedule][:id]
        quantity = item[:quantity]
        subsidized = pricing.fetch(schedule_id).benefits.sum { |_, u| u }
        quantity - subsidized
      end
    }
  end

  def reject_update(order, reason)
    redirect_to order_path(order), alert: t("validations.#{reason}"), status: :see_other
  end

  def reject_order(reason)
    redirect_to dashboard_cart_path, inertia: {
      errors: { order_error: t("validations.#{reason}") }
    }, status: :see_other
  end

  def order_error_reason(order)
    return :provider_closed if order.errors[:schedule_id].include?(t("validations.provider_closed"))
    return :order_deadline_passed if order.errors[:schedule_id].include?(t("validations.order_deadline_passed"))
    return :invalid_options if order.errors[:base].include?(t("validations.invalid_options"))

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

  # La dirección actual del pedido se mantiene como opción aunque no esté
  # guardada, para que modificar la cantidad no obligue a cambiarla.
  def delivery_address_options(consumer, order)
    options = consumer.delivery_address_options
    return options if order.address.blank? || options.pluck(:address).include?(order.address)

    options + [ { id: "current", label: t("pages.orders.addresses.current"), address: order.address } ]
  end

  # El cupo del schedule ya descuenta esta orden, así que el máximo que el
  # empleado puede elegir es lo que queda más lo que ya tiene reservado.
  # Del parámetro solo se confía el id del grupo y los valores: el nombre se toma
  # del plato, así la copia guardada no depende de lo que mande el cliente.
  def selected_options_for(menu, options)
    groups = menu&.option_groups.to_a.index_by(&:id)

    options.to_a.filter_map do |option|
      group = groups[option[:group_id].to_i]
      values = Array(option[:values]).map(&:to_s).compact_blank
      next if group.nil? || values.empty?

      { group_id: group.id, name: group.name, values: }
    end
  end

  def max_quantity(order)
    return order.amount.to_i if order.schedule.nil?

    order.schedule.remaining_amount + order.amount.to_i
  end

  def update_params
    params.expect(order: [ :quantity, :address, :notes, options: [ [ :group_id, { values: [] } ] ] ])
  end

  def order_params
    params.expect(order: [ :address, items: [ [ :schedule_id, :quantity, :notes, { options: [ [ :group_id, { values: [] } ] ] } ] ] ])
  end

  def pricing_params
    params.expect(items: [ [ :schedule_id, :quantity ] ])
  end

  def set_consumer
    @consumer = Current.user.consumer
  end
end
