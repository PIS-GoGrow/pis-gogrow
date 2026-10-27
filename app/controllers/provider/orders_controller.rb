# frozen_string_literal: true

class Provider::OrdersController < Provider::InertiaController
  def index
    @today = Date.current.iso8601
    @upcoming_orders = orders_in(:upcoming)
    @past_orders = orders_in(:history)
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

    if order.decide(status, reason:, details:, by: Current.user)
      redirect_back_or_to provider_orders_path, notice: t("flash.order_#{status}"), status: :see_other
    else
      alert = order.errors.full_messages.to_sentence.presence || t("validations.order_not_pending")
      redirect_back_or_to provider_orders_path, alert:, status: :see_other
    end
  end

  # Al proveedor le aparecen las órdenes ordenadas según el día de entrega,
  # y según cuándo se hicieron. Una orden para hoy que se hizo recién, se muestra
  # primero.
  def orders_in(period)
    today = Date.current

    if period == :history
      provider_orders.where("COALESCE(schedules.date, orders.delivery_date) < ?", today)
                     .order(Arel.sql("COALESCE(schedules.date, orders.delivery_date) DESC, orders.created_at DESC"))
    else
      provider_orders.where("COALESCE(schedules.date, orders.delivery_date) >= ?", today)
                     .order(Arel.sql("COALESCE(schedules.date, orders.delivery_date) ASC, orders.created_at DESC"))
    end
  end

  def provider_orders
    Current.user.provider.orders.left_joins(:schedule).preload(consumer: [ :user, :company ], schedule: :menu)
  end
end
