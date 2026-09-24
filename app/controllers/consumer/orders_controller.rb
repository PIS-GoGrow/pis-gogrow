# frozen_string_literal: true

class Consumer::OrdersController < Consumer::InertiaController
  def create
    consumer = Current.user.consumer
    requested_items = order_params.fetch(:items)
    benefit_percentage = consumer.current_benefit&.percentage.to_i
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
      schedules = Schedule.includes(menu: :provider).where(id: schedule_ids.uniq, date: allowed_dates).order(:id).lock.index_by(&:id)
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

  def delivery_addresses(consumer)
    [ consumer.address, consumer.company.address ].compact_blank
  end

  def order_params
    params.expect(order: [ :address, items: [ [ :schedule_id, :quantity, :notes ] ] ])
  end
end
