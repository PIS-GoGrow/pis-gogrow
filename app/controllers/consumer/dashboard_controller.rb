# frozen_string_literal: true

class Consumer::DashboardController < Consumer::InertiaController
  def index
    @consumer = Current.user.consumer
    @week = week_data
    @schedules = schedule_data
    @benefit = benefit_data
    @addresses = address_data
    @order_confirmation = order_confirmation_data
  end

  private

  def week_data
    start_date = Date.current.beginning_of_week(:monday)

    {
      start_date: start_date.iso8601,
      end_date: (start_date + 4.days).iso8601,
      days: (start_date..(start_date + 4.days)).map do |date|
        { date: date.iso8601, weekday: I18n.l(date, format: "%a"), day: date.day }
      end
    }
  end

  def schedule_data
    range = Date.iso8601(@week[:start_date])..Date.iso8601(@week[:end_date])

    Schedule.includes(:orders, menu: [ :reviews, { provider: :user } ]).where(date: range).order(:date, :id).map do |schedule|
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
          provider_name: menu.provider.user&.name || "Proveedor",
          home_delivery: menu.provider.home_delivery?,
          reviews: menu.reviews.order(created_at: :desc).limit(4).map do |review|
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
    benefit = active_benefit
    used = @consumer.orders.where(created_at: Date.current.all_month).where.not(status: :canceled).sum(:amount)

    {
      limit: benefit&.amount.to_i,
      used:,
      percentage: benefit&.percentage.to_i.clamp(0, 100)
    }
  end

  def active_benefit
    @consumer.benefits.where("due_date >= ?", Date.current).order(:due_date).first
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

    orders_by_id = @consumer.orders.includes(schedule: { menu: { provider: :user } }).where(id: order_ids).index_by(&:id)
    return unless orders_by_id.size == order_ids.size

    orders = order_ids.map { |id| orders_by_id.fetch(id) }

    {
      total: orders.sum(&:discounted_price).to_f,
      orders: orders.map do |order|
        menu = order.schedule.menu
        {
          id: order.id,
          date: order.schedule.date.iso8601,
          address: order.address,
          address_label: delivery_label(order.address),
          provider_name: menu.provider.user&.name || "Proveedor",
          name: menu.name,
          quantity: order.amount,
          discounted_price: order.discounted_price.to_f
        }
      end
    }
  end

  def delivery_label(address)
    return "Oficina" if address == @consumer.company.address
    return "Casa" if address == @consumer.address

    "Entrega"
  end
end
