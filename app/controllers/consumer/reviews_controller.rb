# frozen_string_literal: true

class Consumer::ReviewsController < Consumer::InertiaController
  def new
    @order = reviewable_order
  end

  def create
    order = reviewable_order

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
  end

  def thanks
  end

  private

  # El find va sobre los pedidos del empleado y pedir calificar uno que no es
  # elegible (ajeno, no confirmado, futuro o ya calificado) es un 404: esconder el
  # botón no alcanza como guarda del endpoint.
  def reviewable_order
    order = Current.user.consumer.orders.preload(schedule: :menu).find(params[:order_id])
    raise ActiveRecord::RecordNotFound unless order.reviewable?

    order
  end

  def review_params
    params.permit(:rating, :description)
  end
end
