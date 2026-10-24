# frozen_string_literal: true

class Provider::DashboardController < Provider::InertiaController
  def index
    @provider = Current.user.provider
    today_orders =
      Order.joins(schedule: :menu)
           .where(menus: { provider_id: @provider.id })
           .where(schedules: { date: Date.current })
           .where.not(status: [ :cancelled, :rejected ])
    month = Provider::ActivitySummary.new(@provider, Date.current)

    @today = I18n.l(Date.current, format: "%A %-d de %B").capitalize
    @today_orders_count = today_orders.count
    @pending_orders_count = today_orders.pending.count
    @office_orders_count = today_orders.office.count
    @home_orders_count = today_orders.home.count
    @order_deadline = @provider.order_deadline && I18n.l(@provider.order_deadline, format: "%H:%M")
    @order_deadline_passed_today = @provider.order_deadline_passed_today?
    @month_orders_count = month.orders_count
    @month_dishes_count = month.dishes_count
    @average_rating = month.average_rating
    @completed_sections_count = @provider.completed_sections_count
    @sections_total = @provider.total_sections_count
  end
end