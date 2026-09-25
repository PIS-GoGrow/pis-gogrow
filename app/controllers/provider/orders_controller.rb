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

  def confirm
    decide(:confirmed)
  end

  def reject
    decide(:rejected, reason: params[:reason], details: params[:details])
  end

  private

  # Vuelve a la pantalla desde la que se decidió, que puede ser la lista o el
  # detalle del pedido.
  def decide(status, reason: nil, details: nil)
    order = provider_orders.find(params[:id])

    if order.decide(status, reason:, details:)
      redirect_back_or_to provider_orders_path, notice: t("flash.order_#{status}"), status: :see_other
    else
      alert = order.errors.full_messages.to_sentence.presence || t("validations.order_not_pending")
      redirect_back_or_to provider_orders_path, alert:, status: :see_other
    end
  end

  def provider_orders
    Current.user.provider.orders.preload(consumer: [ :user, :company ], schedule: :menu)
  end
end
