# frozen_string_literal: true

class Provider::OrdersController < Provider::InertiaController
  def index
    # Al proveedor le aparecen las órdenes ordenadas según el día de entrega,
    # y según cuándo se hicieron. Una orden para hoy que se hizo recién, se muestra
    # primero.
    @orders =
      provider_orders.where(schedules: { date: Date.current.. })
                     .order("schedules.date ASC, orders.created_at DESC")
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
