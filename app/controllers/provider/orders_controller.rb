# frozen_string_literal: true

class Provider::OrdersController < Provider::InertiaController
  def index
    @orders = provider_orders.where(schedules: { date: Date.current }).order(created_at: :desc)
  end

  # El find va sobre los pedidos del proveedor y no sobre Order: pedir el de
  # otro proveedor tiene que ser un 404, no una página ajena.
  def show
    @order = provider_orders.find(params[:id])
  end

  private

  def provider_orders
    Current.user.provider.orders.preload(consumer: [ :user, :company ], schedule: :menu)
  end
end
