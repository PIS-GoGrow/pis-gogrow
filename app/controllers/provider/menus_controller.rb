# frozen_string_literal: true

class Provider::MenusController < Provider::InertiaController
  def new
    provider = Current.user.provider

    @today = Date.current.iso8601
    @maximum_publish_date = Calendar.new.maximum_publish_date.iso8601
    @default_date = default_date
    @saved_menus = provider.menus.saved.order(:name)
    # Qué plato guardado está publicado en qué fecha; el front lo cruza con la fecha elegida.
    @published = Schedule.joins(:menu)
                        .where(menus: { provider_id: provider.id }, date: Date.current..)
                        .pluck(:date, Arel.sql("COALESCE(menus.base_menu_id, menus.id)"))
                        .map { |date, menu_id| { date: date.iso8601, menu_id: } }
  end

  def publish
    publish = Menus::Publish.new(provider: Current.user.provider, menu_ids: params[:menu_ids], date: params[:date])

    if publish.call
      redirect_to new_provider_menu_path
    else
      redirect_to new_provider_menu_path, inertia: { errors: publish.errors }
    end
  end

  def create
    create = Menus::Create.new(provider: Current.user.provider, attributes: menu_params, agenda: agenda_params.to_h)

    if create.call
      redirect_to new_provider_menu_path
    else
      redirect_to new_provider_menu_path, inertia: { errors: create.errors }
    end
  end

  # Con schedule_id se edita el plato tal como está programado ese día, que
  # puede ser una variante del plato guardado.
  def edit
    saved_menu = Current.user.provider.menus.saved.find(params[:id])
    schedule = Schedule.where(menu_id: saved_menu.family_ids, date: Date.current..).find(params[:schedule_id]) if params[:schedule_id].present?

    @menu = schedule&.menu || saved_menu
    @saved_menu_id = saved_menu.id
    @return_to = return_path
    @today = Date.current.iso8601
    @schedule_date = schedule&.date&.iso8601
    @agenda = initial_agenda(saved_menu, schedule)
    @scheduled_days = Schedule.where(menu_id: saved_menu.family_ids, date: Date.current..).includes(:orders).order(:date).map do |s|
      { date: s.date.iso8601, confirmed_orders: s.orders.count(&:confirmed?) }
    end
    @maximum_publish_date = Calendar.new.maximum_publish_date.iso8601
  end

  def update
    menu = Current.user.provider.menus.saved.find(params[:id])
    update = Menus::Update.new(
      menu:,
      attributes: menu_params.to_h.deep_symbolize_keys,
      agenda: agenda_params.to_h,
      scope: params[:scope],
      confirmed_orders: params[:confirmed_orders],
      by: Current.user
    )
    path = edit_provider_menu_path(menu, schedule_id: params[:schedule_id].presence, return_to: params[:return_to].presence)

    if update.call
      redirect_to path
    else
      redirect_to path, inertia: { errors: update.errors }
    end
  end

  def destroy
    menu = Current.user.provider.menus.saved.find(params[:id])

    Menus::Delete.new(menu:, confirmed_orders: params[:confirmed_orders], by: Current.user).call

    redirect_to schedules_path(tab: "saved")
  end

  private

  # El día desde el que se tocó "Agregar platos": el formulario lo trae elegido.
  # Solo vale si ese día se puede publicar.
  def default_date
    date = Date.iso8601(params[:date].to_s)
    date.iso8601 if date.on_weekday? && date >= Date.current && date <= Calendar.new.maximum_publish_date
  rescue Date::Error
    nil
  end

  # A dónde vuelve el proveedor al terminar de editar: la página desde la que
  # entró, que llega en return_to. Solo se aceptan rutas de la propia app, así
  # el parámetro no sirve para redirigir a otro sitio.
  def return_path
    path = params[:return_to].to_s
    path.match?(%r{\A/(?![/\\])}) ? path : schedules_path
  end

  def initial_agenda(saved_menu, schedule)
    today = Date.current
    menu = schedule&.menu
    variant_agenda = menu.agendas.first if menu&.variant?
    upcoming_schedule = schedule if schedule && schedule.date >= today

    if variant_agenda&.ends_on && variant_agenda.ends_on >= today
      # Variante de rango vigente
      {
        mode: "range",
        weekdays: variant_agenda.weekdays,
        starts_on: [ variant_agenda.starts_on, today ].max.iso8601,
        ends_on: variant_agenda.ends_on.iso8601,
        date: nil,
        amount: variant_agenda.amount
      }
    elsif upcoming_schedule && menu.variant?
      # Variante de día o congelada: se edita ese día, no el plato guardado
      {
        mode: "single",
        weekdays: [ upcoming_schedule.date.cwday ],
        starts_on: nil,
        ends_on: nil,
        date: upcoming_schedule.date.iso8601,
        amount: upcoming_schedule.amount
      }
    elsif (current = saved_menu.agenda_on([ upcoming_schedule&.date, today ].compact.max))
      # Plato guardado con agenda que cubre esa fecha
      {
        mode: "weekly",
        weekdays: current.weekdays,
        starts_on: [ current.starts_on, today ].max.iso8601,
        ends_on: nil,
        date: nil,
        amount: current.amount
      }
    elsif upcoming_schedule
      # Schedule manual, que ninguna agenda cubre
      {
        mode: "single",
        weekdays: [ upcoming_schedule.date.cwday ],
        starts_on: nil,
        ends_on: nil,
        date: upcoming_schedule.date.iso8601,
        amount: upcoming_schedule.amount
      }
    else
      { mode: "none", weekdays: [], starts_on: nil, ends_on: nil, date: nil, amount: nil }
    end
  end

  def agenda_params
    params.fetch(:agenda, {}).permit(:mode, :date, :starts_on, :ends_on, :amount, weekdays: [])
  end

  def menu_params
    params.expect(menu: [
      :name, :price, :description,
      option_groups_attributes: [ [ :id, :name, :limit, :_destroy, options: [] ] ]
    ])
  end
end
