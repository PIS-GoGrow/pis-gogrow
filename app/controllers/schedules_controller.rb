# frozen_string_literal: true

class SchedulesController < Provider::InertiaController
  def index
    provider = Current.user.provider
    menus = provider.menus.saved.order(:id)
    # El job diario es el que completa las agendas; esto cubre los entornos en los
    # que no corre (desarrollo) y lo que haya cambiado desde la última pasada.
    menus.each { Menus::AgendaScheduler.call(it) }

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

    week_end = week_start + 4.days

    schedules =
        Schedule
            .joins(:menu)
            .where(
            menus: { provider_id: provider.id, archived_at: nil },
            date: week_start..week_end
            )
            .order(:date, :id)

    schedules_by_date = schedules.group_by(&:date)

    days = (week_start..week_end).map do |date|
      day_schedules = schedules_by_date.fetch(date, [])

      {
          date: date,
          publishable: (
            date.on_weekday? &&
            date >= Date.current &&
            date <= maximum_publish_date
          ),
          schedules: day_schedules.map do |schedule|
            ScheduleSerializer.new(schedule).to_inertia
          end
      }
    end

    next_week = week_start + 1.week
    next_week_start = next_week > maximum_week_start ? nil : next_week

    render inertia: {
        week: {
            starts_on: week_start,
            ends_on: week_end,
            previous_week_start: week_start - 1.week,
            next_week_start: next_week_start
        },
        days: days,
        saved_menus: menus.map { SavedMenuSerializer.new(it).to_inertia },
        tab: params[:tab] == "saved" ? "saved" : "week",
        selected_date: params[:date].presence,
        today: Date.current.iso8601
    }
  end

  def availability
    schedule = Current.user.provider.schedules.find(params[:id])

    if schedule.set_availability(available: params.expect(:available), by: Current.user)
      redirect_to schedules_path(week_start: schedule.date.beginning_of_week(:monday).to_s)
    else
      redirect_to schedules_path, inertia: { errors: schedule.errors }
    end
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

    unless date.on_weekday?
      redirect_to schedules_path,
                  inertia: { errors: { date: [ "Solo se pueden publicar menús de lunes a viernes" ] } }
      return
    end

    if date > maximum_publish_date
      redirect_to schedules_path,
                  inertia: { errors: { date: [ "La fecha está fuera del rango permitido de publicación" ] } }
      return
    end

    unless valid_initial_stock?(items)
      redirect_to schedules_path,
                  inertia: { errors: { amount: [ "El stock inicial debe ser un entero entre 1 y #{Schedule::MAX_AMOUNT}" ] } }
      return
    end

    if published_date?(provider, date)
      redirect_to schedules_path,
                  inertia: { errors: { date: [ "Ya existe un menú publicado para esta fecha" ] } }
      return
    end

    Schedule.transaction do
      items.each do |item|
        menu = provider.menus.saved.find(item.require(:menu_id))

        menu.schedules.create!(
        date: date,
        amount: item.require(:amount)
        )
      end
    end

    redirect_to schedules_path(week_start: date.beginning_of_week(:monday).to_s)
  end

  def destroy
    schedule = Current.user.provider.schedules.find(params[:id])
    week_start = schedule.date.beginning_of_week(:monday).to_s

    if schedule.date < Date.current
      redirect_to schedules_path(week_start:),
                  inertia: { errors: { date: [ "No se puede quitar un plato de una fecha pasada" ] } }
      return
    end

    Schedule.transaction do
      schedule.orders.where(status: [ :pending, :confirmed ]).each do |order|
        order.withdraw!(by: Current.user)
      end

      saved_menu = schedule.menu.saved_menu
      schedule.destroy!
      saved_menu.skip_date!(schedule.date)
    end

    redirect_to schedules_path(week_start:),
                notice: "Plato quitado del menú.",
                status: :see_other
  end

  private

  def valid_initial_stock?(items)
    items.all? do |item|
      amount = Integer(item.require(:amount), exception: false)
      amount.present? &&
        amount.positive? &&
        amount <= Schedule::MAX_AMOUNT
    end
  end

  def published_date?(provider, date)
    provider.menus
            .joins(:schedules)
            .where(schedules: { date: date })
            .exists?
  end

  def maximum_publish_date
    @maximum_publish_date ||= Calendar.new.maximum_publish_date
  end

  # La semana se pide con week_start o, si no viene, con un día (date): así se
  # vuelve a la semana de un día sin conocer su lunes.
  def requested_week_start
    requested = params[:week_start].presence || params[:date].presence
    return Date.current.beginning_of_week(:monday) if requested.blank?

    Date.iso8601(requested).beginning_of_week(:monday)
  rescue Date::Error
    nil
  end
end
