# frozen_string_literal: true

class Provider::DashboardController < Provider::InertiaController
  def index
    @provider = Current.user.provider
    today_orders =
      Order.joins(schedule: :menu)
           .where(menus: { provider_id: @provider.id })
           .where(schedules: { date: Date.current })
           .where.not(status: [ :cancelled, :rejected ])
    month = Provider::ActivitySummary.new(@provider, Date.current.all_month)

    @today = DateFormat.long(Date.current)
    @today_orders_count = today_orders.count
    @pending_orders_count = today_orders.pending.count
    @office_orders_count = today_orders.office.count
    @home_orders_count = today_orders.home.count
    @order_deadline = @provider.order_deadline && I18n.l(@provider.order_deadline, format: "%H:%M")
    @order_deadline_passed_today = @provider.order_deadline_passed_today?
    @seconds_until_order_deadline = @provider.seconds_until_order_deadline
    @month_orders_count = month.orders_count
    @month_dishes_count = month.dishes_count
    @average_rating = month.average_rating
    @top_rated = top_rated_dishes
    @completed_sections_count = @provider.completed_sections_count
    @sections_total = @provider.total_sections_count
  end

  private

  # Platos del proveedor mejor valorados, por promedio de sus calificaciones
  # válidas. Se agrupa por nombre para unir las variantes del mismo plato.
  def top_rated_dishes
    Review.joins(:menu)
          .where(menus: { provider_id: @provider.id })
          .where.not(rating: nil)
          .group("menus.name")
          .order(Arel.sql("AVG(reviews.rating) DESC, menus.name ASC"))
          .limit(5)
          .pluck(Arel.sql("menus.name"), Arel.sql("ROUND(AVG(reviews.rating)::numeric, 1)"))
          .map { |name, rating| { name:, rating: rating.to_f } }
  end
end
