# frozen_string_literal: true

class Consumer::OrdersController < Consumer::InertiaController
  before_action :set_consumer

  def index
    orders = @consumer.orders.preload(:review, provider: :user, schedule: { menu: { provider: :user } })

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
      :review, schedule: { menu: [ :option_groups, { provider: :user } ] }
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
    result = Orders::Place.new(
      consumer: @consumer,
      items: order_params[:items],
      address: order_params[:address]
    ).call

    if result.success?
      redirect_to dashboard_confirmation_path(confirmed_order_ids: result.orders.map(&:id)),
                  notice: t("flash.cart_confirmed"),
                  status: :see_other
    else
      reject_order(result.record ? order_error_reason(result.record) : result.error)
    end
  rescue ActionController::ParameterMissing
    # Antes lo capturaba el `rescue KeyError`.
    reject_order(:empty_cart)
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

  # Le provee al frontend una interfaz de JSON para el servicio OrderPricing, para poder
  # calcular el precio de pedidos en el carrito
  def pricing
    items = build_requested_items

    pricings = Orders::Pricing.new(@consumer).call(items)

    render json: Consumer::OrderPricingSerializer.new(items, pricings)
  end

  private

  # Convierte las id de schedule
  def build_requested_items
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

    requested_items.filter_map do |item|
      schedule = schedules.dig(item[:schedule_id].to_i)
      { schedule:, quantity: item[:quantity].to_i, benefits: item[:benefits] } if schedule
    end
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

  # La dirección actual del pedido se mantiene como opción aunque no esté
  # guardada, para que modificar la cantidad no obligue a cambiarla.
  def delivery_address_options(consumer, order)
    options = consumer.delivery_address_options
    return options if order.address.blank? || options.pluck(:address).include?(order.address)

    options + [ { id: "current", label: t("pages.orders.addresses.current"), address: order.address } ]
  end

  def max_quantity(order)
    return order.amount.to_i if order.schedule.nil?

    order.schedule.remaining_amount + order.amount.to_i
  end

  def update_params
    params.expect(order: [ :quantity, :address, :notes, options: [ [ :group_id, { values: [] } ] ] ])
  end

  def order_params
    params.expect(order: [ :address, items: [ [ :schedule_id, :quantity, :notes, { options: [ [ :group_id, { values: [] } ] ] }, benefits: [] ] ] ])
  end

  def pricing_params
    params.expect(items: [ [ :schedule_id, :quantity, benefits: [] ] ])
  end

  def set_consumer
    @consumer = Current.user.consumer
  end
end
