# frozen_string_literal: true

class Consumer::DashboardController < Consumer::InertiaController
  def index
    @consumer = Current.user.consumer
    @week = week_data
    @schedules = schedule_data
    @benefit = benefit_data
    @addresses = address_data
  end

  def confirmation
    @consumer = Current.user.consumer
    order_confirmation = order_confirmation_data
    @total = order_confirmation[:total]
    @orders = order_confirmation[:orders]
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
    schedules = Schedule.includes(:orders, menu: [ :reviews, { provider: :user } ])
                        .where(date: week_range)
                        .order(:date, :id)

    schedules.map do |schedule|
      menu = schedule.menu

      {
        id: schedule.id,
        date: schedule.date.iso8601,
        remaining: schedule.remaining_amount,
        sold_out: !schedule.available?,
        menu: {
          id: menu.id,
          name: menu.name,
          description: menu.description,
          price: menu.price.to_f,
          fillings: menu.fillings,
          sauces: menu.sauces,
          provider_name: menu.provider_name,
          home_delivery: menu.provider.home_delivery?,
          reviews: menu.reviews.first(4).map do |review|
            {
              id: review.id,
              description: review.description,
              rating: review.rating,
              created_at: review.created_at.to_date.iso8601
            }
          end
        }
      }
    end
  end

  def benefit_data
    {
      limit: @consumer.benefit_available / 4,
      used: @consumer.subsidized_meals_used_this_week,
      percentage: @consumer.current_benefit&.percentage.to_i.clamp(0, 100),
      monthly_limit: @consumer.benefit_available,
      monthly_used: @consumer.subsidized_meals_used_this_month,
      monthly_remaining: @consumer.remaining_subsidized_meals
    }
  end

  def address_data
    [
      { id: "office", label: "Oficina", address: @consumer.company.address },
      { id: "home", label: "Casa", address: @consumer.address }
    ].select { |address| address[:address].present? }
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
          name: menu.name,
          quantity: order.amount,
          discounted_price: order.discounted_price.to_f
        }
      end
    }
  end

  # Si hoy es sábado o domingo, queremos mostrar los menús para la semana que viene.
  # Si no, mostramos los de esta.
  def week_range
    @week_range ||= begin
      start = Date.current.on_weekend? ? Date.current.next_week(:monday) : Date.current.beginning_of_week(:monday)
      start..(start + 4.days)
    end
  end
end
