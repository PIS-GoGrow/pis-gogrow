# frozen_string_literal: true

class Consumer::DashboardController < Consumer::InertiaController
  def index
    @consumer = Current.user.consumer
    @week = week_data
    @schedules = schedule_data
    @benefit = benefit_data
    @providers = Provider.includes(:user).all
    @favorites = favorite_data
    @frequent = frequent_data
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
      today: Date.current.iso8601,
      start_date: week_range.first.iso8601,
      end_date: week_range.last.iso8601,
      days: week_range.map do |date|
        { date: date.iso8601, weekday: I18n.l(date, format: "%a"), day: date.day }
      end
    }
  end

  def schedule_data
    schedules = Schedule.on_active_menus.includes(menu: [ { reviews: { consumer: :user } }, :option_groups, { provider: [ :user, :closures ] } ])
                        .where(date: week_range)
                        .order(:date, :id)
                        .reject(&:provider_closed?)

    ordered = ordered_amounts(schedules.map(&:id))

    schedules.map { dish_data(it).merge(ordered: ordered[it.id]) }
  end

  # Cada línea del carrito se guarda como un pedido aparte, así que un mismo
  # plato puede tener unidades pendientes y confirmadas a la vez.
  def ordered_amounts(schedule_ids)
    amounts = @consumer.orders
                       .where(schedule_id: schedule_ids, status: [ :pending, :confirmed ])
                       .group(:schedule_id, :status)
                       .sum(:amount)

    schedule_ids.index_with do |schedule_id|
      { pending: amounts[[ schedule_id, "pending" ]].to_i, confirmed: amounts[[ schedule_id, "confirmed" ]].to_i }
    end
  end

  def favorite_data
    { menus: menu_shortcuts(@consumer.favorite_ids("Menu")), provider_ids: @consumer.favorite_ids("Provider") }
  end

  def frequent_data
    { menus: menu_shortcuts(@consumer.frequent(:menu)), provider_ids: @consumer.frequent(:provider) }
  end

  # Los platos se muestran aunque hoy no tengan programación: sirven de
  # referencia y el cliente decide si se pueden pedir según el día elegido.
  def menu_shortcuts(menu_ids)
    menus = Menu.where(id: menu_ids, archived_at: nil).includes(provider: :user).index_by(&:id)

    menu_ids.filter_map do |id|
      menu = menus[id]
      next unless menu

      {
        id: menu.id,
        name: menu.name,
        description: menu.description,
        price: menu.price.to_f,
        provider_id: menu.provider_id,
        provider_name: menu.provider_name
      }
    end
  end

  def benefit_data
    pricing = Orders::Pricing.new(@consumer)
    week_date = week_range.first

    {
      percentage: @consumer.monthly_benefit_percentage(date: week_date),
      monthly_limit: @consumer.monthly_benefit_available(date: week_date),
      monthly_used: @consumer.monthly_benefit_used_this_month(date: week_date),
      monthly_remaining: @consumer.remaining_monthly_benefit(date: week_date),
      weekly_limit: @consumer.weekly_benefit_limit(date: week_date),
      weekly_used: @consumer.weekly_benefit_used(date: week_date),
      weekly_remaining: @consumer.remaining_weekly_benefit(date: week_date),
      specials: @consumer.special_benefits.map do |benefit|
        {
          id: benefit.id,
          name: benefit.description.to_s,
          percentage: benefit.percentage,
          remaining: pricing.remaining_uses(benefit),
          starts_on: benefit.starts_on&.iso8601,
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
