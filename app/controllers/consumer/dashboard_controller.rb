# frozen_string_literal: true

class Consumer::DashboardController < Consumer::InertiaController
  def index
    @consumer = Current.user.consumer
    @week = week_data
    @schedules = schedule_data
    @benefit = benefit_data
    @closures = ProviderClosure.upcoming.includes(provider: :user)
  end

  def confirmation
    @consumer = Current.user.consumer
    order_confirmation = order_confirmation_data
    return redirect_to dashboard_path unless order_confirmation

    @total = order_confirmation[:total]
    @orders = order_confirmation[:orders]
  end

  def cart
    @consumer = Current.user.consumer

    @addresses = @consumer.delivery_address_options
    @benefit = benefit_data
  end

  private

  # TODO: Eventualmente habría que mover todos los métodos siguientes que están acá
  # a serializers aparte. Esto permetiría reutilizarlos y hacer todo un poco más legible
  # (es difícil ver qué información tiene schedule_data)

  def week_data
    {
      start_date: week_range.first.iso8601,
      end_date: week_range.last.iso8601,
      days: week_range.map do |date|
        { date: date.iso8601, weekday: I18n.l(date, format: "%a"), day: date.day }
      end
    }
  end

  def schedule_data
    schedules = Schedule.on_active_menus.includes(:orders, menu: [ { reviews: { consumer: :user } }, :option_groups, { provider: [ :user, :closures ] } ])
                        .where(date: week_range)
                        .order(:date, :id)

    schedules.reject(&:provider_closed?).map { dish_data(it) }
  end

  def benefit_data
    pricing = OrderPricing.new(@consumer)

    {
      percentage: @consumer.monthly_benefit_percentage,
      monthly_limit: @consumer.monthly_benefit_available,
      monthly_used: @consumer.monthly_benefit_used_this_month,
      monthly_remaining: @consumer.remaining_monthly_benefit,
      specials: @consumer.special_benefits.map do |benefit|
        {
          id: benefit.id,
          name: benefit.description.to_s,
          percentage: benefit.percentage,
          remaining: pricing.remaining_uses(benefit),
          due_date: benefit.due_date&.iso8601
        }
      end
    }
  end

  def order_confirmation_data
    order_ids = Array(params[:confirmed_order_ids]).filter_map { |id| Integer(id, exception: false) }.uniq
    return if order_ids.empty?

    orders = @consumer.orders.includes(schedule: { menu: { provider: :user } }).where(id: order_ids)
    return unless orders.size == order_ids.size

    {
      total: orders.sum(&:discounted_price).to_f,
      orders: orders.map do |order|
        menu = order.schedule.menu
        {
          id: order.id,
          date: order.schedule.date.iso8601,
          address: order.address,
          delivery_method: order.delivery_method,
          provider_name: menu.provider_name,
          name: order.menu_name,
          quantity: order.amount,
          discounted_price: order.discounted_price.to_f
        }
      end
    }
  end

  def week_range
    @week_range ||= Calendar.new.schedule_week_range
  end
end
