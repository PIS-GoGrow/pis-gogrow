# frozen_string_literal: true

class OrdersController < InertiaController
  before_action :authenticate_consumer

  def index
    orders = Current.user.consumer.orders.preload(schedule: { menu: { provider: :user } })

    @upcoming_orders = orders.upcoming
    @past_orders = orders.history
  end

  # El find va sobre las órdenes del empleado y no sobre Order: pedir la de otro
  # tiene que ser un 404, no una página ajena.
  def show
    @order = Current.user.consumer.orders.preload(schedule: { menu: { provider: :user } }).find(params[:id])
  end
end
