# frozen_string_literal: true

class Provider::OrdersController < Provider::InertiaController
  def index
    @orders = Current.user.provider.orders
      .where(schedules: { date: Date.current })
      .includes(consumer: :user, schedule: :menu)
      .order(created_at: :desc)
  end
end
