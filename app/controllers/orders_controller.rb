# frozen_string_literal: true

class OrdersController < InertiaController
  before_action :authenticate_consumer

  def create
    consumer = Current.user.consumer
    requested_items = order_params.fetch(:items)
    benefit_percentage = active_benefit_for(consumer)&.percentage.to_i
    raise ActiveRecord::RecordNotFound if requested_items.empty?

    Order.transaction do
      schedules = Schedule.includes(:menu).where(id: requested_items.pluck(:schedule_id), date: current_week).order(:id).lock.index_by(&:id)
      raise ActiveRecord::RecordNotFound unless schedules.size == requested_items.size
      raise ActiveRecord::RecordNotFound unless delivery_addresses(consumer).include?(order_params[:address])

      requested_items.each do |item|
        schedule = schedules.fetch(item[:schedule_id].to_i)
        order = Order.reserve(
          consumer:,
          schedule:,
          quantity: item[:quantity].to_i,
          notes: item[:notes],
          address: order_params[:address],
          discount_percentage: benefit_percentage
        )
        raise ActiveRecord::RecordInvalid, order unless order.persisted?
      end
    end

    redirect_to dashboard_path, notice: "Pedido confirmado", status: :see_other
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound, KeyError
    redirect_to dashboard_path, inertia: {
      errors: { order_error: "Uno de los platos ya no tiene disponibilidad. Revisá el carrito e intentá nuevamente." }
    }, status: :see_other
  end

  private

  def active_benefit_for(consumer)
    consumer.benefits.where("due_date >= ?", Date.current).order(:due_date).first
  end

  def current_week
    Date.current.beginning_of_week(:monday)..Date.current.beginning_of_week(:monday).advance(days: 4)
  end

  def delivery_addresses(consumer)
    [ consumer.address, consumer.company.address ].compact_blank
  end

  def order_params
    params.expect(order: [ :address, items: [ [ :schedule_id, :quantity, :notes ] ] ])
  end
end
