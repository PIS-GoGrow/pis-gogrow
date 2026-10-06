# frozen_string_literal: true

class Provider::MenusController < Provider::InertiaController
  def index
    provider = Current.user.provider
    menus = provider.menus.saved.order created_at: :desc

    render inertia: { menus: }
  end

  def new
  end

  def create
    provider = Current.user.provider
    menu = provider.menus.new menu_params

    if menu.save
      redirect_to provider_menus_path
    else
      redirect_to provider_menus_path, inertia: { errors: menu.errors }
    end
  end

  def show
    provider = Current.user.provider
    menu = provider.menus.find(params[:id])

    render inertia: { menu: }
  end

  # Con schedule_id se edita el plato tal como está programado ese día, que
  # puede ser una variante del plato guardado.
  def edit
    saved_menu = Current.user.provider.menus.saved.find(params[:id])
    schedule = Schedule.where(menu_id: saved_menu.family_ids, date: Date.current..).find(params[:schedule_id]) if params[:schedule_id].present?

    @menu = schedule&.menu || saved_menu
    @saved_menu_id = saved_menu.id
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
    path = edit_provider_menu_path(menu, schedule_id: params[:schedule_id].presence)

    if update.call
      redirect_to path
    else
      redirect_to path, inertia: { errors: update.errors }
    end
  end

  def destroy
    provider = Current.user.provider
    menu = provider.menus.find(params[:id])

    if menu.destroy
      redirect_to provider_menus_path
    end
  end

  private

  def initial_agenda(saved_menu, schedule)
    variant_agenda = schedule&.menu&.agendas&.first
    current = saved_menu.current_agenda

    if variant_agenda
      { mode: "range", weekdays: variant_agenda.weekdays, starts_on: [ variant_agenda.starts_on, Date.current ].max.iso8601,
        ends_on: variant_agenda.ends_on.iso8601, date: nil, amount: variant_agenda.amount }
    elsif schedule
      { mode: "single", weekdays: [ schedule.date.cwday ], starts_on: nil, ends_on: nil, date: schedule.date.iso8601,
        amount: schedule.amount }
    elsif current
      { mode: "weekly", weekdays: current.weekdays, starts_on: [ current.starts_on, Date.current ].max.iso8601,
        ends_on: nil, date: nil, amount: current.amount }
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
