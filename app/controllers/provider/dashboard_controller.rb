# frozen_string_literal: true

class Provider::DashboardController < Provider::InertiaController
  def index
    @provider = Current.user.provider
    today_orders =
      Order.joins(schedule: :menu)
           .where(menus: { provider_id: @provider.id })
           .where(schedules: { date: Date.current })
           .where.not(status: [ :cancelled, :rejected ])
    month_orders =
      Order.joins(schedule: :menu)
           .where(menus: { provider_id: @provider.id })
           .where(schedules: { date: Date.current.all_month })
           .where.not(status: [ :cancelled, :rejected ])

    @today = I18n.l(Date.current, format: "%A, %-d de %B").capitalize
    @today_orders_count = today_orders.count
    @pending_orders_count = today_orders.pending.count
    @office_orders_count = today_orders.office.count
    @home_orders_count = today_orders.home.count
    @order_deadline = @provider.order_deadline && I18n.l(@provider.order_deadline, format: "%H:%M")
    @month_orders_count = month_orders.count
    @month_dishes_count = @provider.menus.count
    @average_rating = Review.joins(:menu).where(menus: { provider_id: @provider.id }).average(:rating)&.round(1)&.to_f
  end
end
