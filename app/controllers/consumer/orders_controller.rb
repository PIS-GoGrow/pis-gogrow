# frozen_string_literal: true

class Consumer::OrdersController < Consumer::InertiaController
  def index
    orders = Current.user.consumer.orders.preload(schedule: { menu: { provider: :user } })

    @upcoming_orders = orders.upcoming
    @past_orders = orders.history
  end

  def show
    consumer = Current.user.consumer
    # El find va sobre las órdenes del empleado y no sobre Order: pedir la de otro
    # tiene que ser un 404, no una página ajena.
    @order = consumer.orders.preload(schedule: { menu: { provider: :user } }).find(params[:id])
    @delivery_addresses = delivery_address_options(consumer)
    @max_quantity = max_quantity(@order)
  end

  def create
    consumer = Current.user.consumer
    requested_items = order_params.fetch(:items)
    benefit_percentage = active_benefit_for(consumer)&.percentage.to_i
    remaining_subsidized = benefit_percentage.positive? ? consumer.remaining_subsidized_meals : 0
    return reject_order(:empty_cart) if requested_items.empty?
    return reject_order(:invalid_address) unless delivery_addresses(consumer).include?(order_params[:address])
    return reject_order(:invalid_quantity) unless requested_items.all? { |item| item[:quantity].to_s.match?(/\A[1-9]\d*\z/) }

    created_orders = []

    Order.transaction do
      consumer.lock!

      remaining_subsidized =
        benefit_percentage.positive? ? consumer.remaining_subsidized_meals : 0
      schedule_ids = requested_items.pluck(:schedule_id)
      schedules = Schedule.includes(menu: :provider).where(id: schedule_ids.uniq, date: current_week).order(:id).lock.index_by(&:id)
      raise ActiveRecord::RecordNotFound unless schedules.size == schedule_ids.uniq.size

      requested_items.each do |item|
        quantity = item[:quantity].to_i

        subsidized_quantity = [
          quantity,
          remaining_subsidized
        ].min

        schedule = schedules.fetch(item[:schedule_id].to_i)
        delivery = consumer.delivery_for(schedule.menu.provider, order_params[:address])
        if delivery[:address].blank?
          reject_order(:office_address_required)
          raise ActiveRecord::Rollback
        end
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

    redirect_to dashboard_path(confirmed_order_ids: created_orders.map(&:id)), notice: t("flash.cart_confirmed"), status: :see_other unless performed?
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound, KeyError
    reject_order(:cart_unavailable)
  end

  def update
    consumer = Current.user.consumer
    order = consumer.orders.find(params[:id])

    return reject_update(order, :invalid_quantity) unless update_params[:quantity].to_s.match?(/\A[1-9]\d*\z/)
    return reject_update(order, :invalid_address) unless delivery_addresses(consumer).include?(update_params[:address])

    delivery = consumer.delivery_for(order.provider, update_params[:address])
    return reject_update(order, :office_address_required) if delivery[:address].blank?

    benefit_percentage = active_benefit_for(consumer)&.percentage.to_i
    modified = order.modify(
      by: Current.user,
      quantity: update_params[:quantity].to_i,
      notes: update_params[:notes],
      delivery:,
      discount_percentage: benefit_percentage,
      remaining_subsidized: benefit_percentage.positive? ? consumer.remaining_subsidized_meals : 0
    )

    if modified
      redirect_to order_path(order), notice: t("flash.order_updated"), status: :see_other
    else
      redirect_to order_path(order), alert: order.errors.full_messages.first || t("validations.order_not_modifiable"), status: :see_other
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

  def active_benefit_for(consumer)
    consumer.benefits.where("due_date >= ?", Date.current).order(:due_date).first
  end

  def current_week
    Date.current.beginning_of_week(:monday)..Date.current.beginning_of_week(:monday).advance(days: 4)
  end

  def delivery_addresses(consumer)
    [ consumer.address, consumer.company.address ].compact_blank
  end

  def delivery_address_options(consumer)
    [
      { id: "office", label: t("pages.orders.addresses.office"), address: consumer.company.address },
      { id: "home", label: t("pages.orders.addresses.home"), address: consumer.address }
    ].select { |address| address[:address].present? }
  end

  # El cupo del schedule ya descuenta esta orden, así que el máximo que el
  # empleado puede elegir es lo que queda más lo que ya tiene reservado.
  def max_quantity(order)
    return order.amount.to_i if order.schedule.nil?

    order.schedule.remaining_amount + order.amount.to_i
  end

  def update_params
    params.expect(order: [ :quantity, :address, :notes ])
  end

  def order_params
    params.expect(order: [ :address, items: [ [ :schedule_id, :quantity, :notes ] ] ])
  end
end
