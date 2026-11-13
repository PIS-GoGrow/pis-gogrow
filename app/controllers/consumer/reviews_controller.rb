# frozen_string_literal: true

class Consumer::ReviewsController < Consumer::InertiaController
  def new
    @order = find_order
    redirect_to_orders_unavailable unless @order.reviewable?
  end

  def create
    order = find_order
    return redirect_to_orders_unavailable unless order.reviewable?

    review = order.build_review(
      consumer: order.consumer,
      menu: order.schedule.menu.saved_menu,
      rating: review_params[:rating],
      description: review_params[:description]
    )

    if review.save(context: :consumer_review)
      redirect_to review_thanks_path, status: :see_other
    else
      redirect_to new_order_review_path(order), inertia: { errors: review.errors }, status: :see_other
    end
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::StatementInvalid
    # El guardado falló por algo que no es validación (p. ej. un doble envío que
    # choca contra el índice único del pedido): la pantalla de error del flujo.
    redirect_to review_error_path, status: :see_other
  end

  def thanks
  end

  def error
  end

  private

  # El find va sobre los pedidos del empleado: pedir uno ajeno o inexistente es un
  # 404. Uno propio que ya no es calificable (ya calificado, cancelado, futuro)
  # vuelve a la lista con un aviso en vez de romper: la lista puede haber quedado
  # con el botón viejo, y el redirect la recarga con el estado real.
  def find_order
    Current.user.consumer.orders.preload(schedule: :menu).find(params[:order_id])
  end

  def redirect_to_orders_unavailable
    redirect_to orders_path, alert: t("flash.review_unavailable"), status: :see_other
  end

  def review_params
    params.permit(:rating, :description)
  end
end
