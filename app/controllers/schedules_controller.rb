# frozen_string_literal: true

class SchedulesController < InertiaController
  before_action :authenticate_provider

  def index
    provider = Current.user.provider
    menus = provider.menus.order(:id)

    serialized_menus = menus.map do |menu|
      MenuSerializer.new(menu).to_inertia
    end

    week_start = requested_week_start

    unless week_start
      redirect_to schedules_path
      return
    end

    maximum_week_start =
        maximum_publish_date.beginning_of_week(:monday)

    if week_start > maximum_week_start
      redirect_to schedules_path(
          week_start: maximum_week_start.to_s
      )
      return
    end

    week_end = week_start.end_of_week(:monday)

    schedules =
        Schedule
            .joins(:menu)
            .where(
            menus: { provider_id: provider.id },
            date: week_start..week_end
            )
            .order(:date, :id)

    schedules_by_date = schedules.group_by(&:date)

    published_dates =
        provider.menus
                .joins(:schedules)
                .where(schedules: { date: week_start..week_end })
                .distinct
                .pluck("schedules.date")

    days = (week_start..week_end).map do |date|
      day_schedules = schedules_by_date.fetch(date, [])
      published = published_dates.include?(date)

      {
          date: date,
          published: published,
          publishable: (
            date >= Date.current &&
            date <= maximum_publish_date &&
            !published
          ),
           schedules: day_schedules.map do |schedule|
            ScheduleSerializer.new(schedule).to_inertia
          end
      }
    end

    render inertia: {
        week: {
            starts_on: week_start,
            ends_on: week_end
        },
        days: days,
        menus: serialized_menus
    }
  end

  def create
    provider = Current.user.provider
    date = Date.iso8601(params.require(:date))
    items = params.require(:items)

    if date < Date.current
      redirect_to schedules_path,
                  inertia: { errors: { date: [ "No se puede publicar un menú para una fecha pasada" ] } }
      return
    end

    if date > maximum_publish_date
      redirect_to schedules_path,
                  inertia: { errors: { date: [ "La fecha está fuera del rango permitido de publicación" ] } }
      return
    end

    unless valid_initial_stock?(items)
      redirect_to schedules_path,
                  inertia: { errors: { amount: [ "El stock inicial debe ser mayor a 0" ] } }
      return
    end

    if published_date?(provider, date)
      redirect_to schedules_path,
                  inertia: { errors: { date: [ "Ya existe un menú publicado para esta fecha" ] } }
      return
    end

    Schedule.transaction do
      items.each do |item|
        menu = provider.menus.find(item.require(:menu_id))

        menu.schedules.create!(
        date: date,
        amount: item.require(:amount)
        )
      end
    end

    redirect_to schedules_path
  end

  def valid_initial_stock?(items)
    items.all? do |item|
      amount = Integer(item.require(:amount), exception: false)
      amount.present? && amount.positive?
    end
  end

  def published_date?(provider, date)
    provider.menus
            .joins(:schedules)
            .where(schedules: { date: date })
            .exists?
  end

  def maximum_publish_date
    Date.current.end_of_week(:monday) + 1.week
  end

    private

  def requested_week_start
    return Date.current.beginning_of_week(:monday) if params[:week_start].blank?

    Date.iso8601(params[:week_start]).beginning_of_week(:monday)

rescue Date::Error
  nil
  end
end
