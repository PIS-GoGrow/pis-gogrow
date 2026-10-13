# frozen_string_literal: true

require "rails_helper"

# Historia IBP-050, criterio 2: "Como proveedor debo poder seleccionar qué fechas
# estará disponible el plato que yo publico".
#
# La repetición semanal ya está en publicar_menu_todas_las_semanas_spec.rb. Acá va
# elegir un único día: qué queda en la base cuando se elige, y hasta qué fechas le
# deja seleccionar al proveedor.
RSpec.describe "Seleccionar el día en que un plato está disponible" do
  fixtures :users, :providers, :menus, :schedules, :consumers, :companies

  # Se viaja a un lunes futuro para que hoy siempre sea un día hábil y la semana
  # publicable sea siempre la misma.
  around do |example|
    travel_to(Date.current.next_occurring(:monday).noon) { example.run }
  end

  let(:milanesa) { menus(:milanesa) }
  let(:monday) { Date.current }
  let(:tuesday) { Date.current + 1 }
  let(:wednesday) { Date.current + 2 }
  let(:friday) { Date.current + 4 }

  before do
    Order.destroy_all
    Schedule.destroy_all
    sign_in users(:provider_user), role: :provider
  end

  def fill_name(value)
    fill_in "name", with: value, fill_options: { clear: :backspace }
  end

  def apply_to_saved_dish
    click_button "Modificar"
    find("label", text: "Modificar el plato guardado").click
    click_button "Aplicar cambios"
  end

  # Criterio 2
  it "publica el plato el día elegido y solo en ese día" do
    visit_hydrated edit_provider_menu_path(milanesa)

    choose_weekday("Martes")
    expect(find("#agenda-date").text).not_to eq("Elegí una fecha")

    fill_name("Milanesa napolitana")
    apply_to_saved_dish

    expect(page).to have_content("¡Plato modificado!")

    expect(milanesa.reload.name).to eq("Milanesa napolitana")

    schedules = Schedule.where(menu_id: milanesa.family_ids, date: Date.current..)
    expect(schedules.pluck(:date)).to eq([ tuesday ])
    expect(schedules.sole.menu).to eq(milanesa)
    expect(milanesa.agendas).to be_empty
  end

  # Criterio 2: el último día que la aplicación deja publicar es el viernes de la
  # semana siguiente, y tiene que ser elegible.
  it "permite elegir el último día del período de publicación" do
    last_publishable = Calendar.new.maximum_publish_date

    visit_hydrated edit_provider_menu_path(milanesa)

    choose_weekday("Viernes")
    pick_date "#agenda-date", last_publishable

    fill_name("Milanesa napolitana")
    apply_to_saved_dish

    expect(page).to have_content("¡Plato modificado!")

    expect(Schedule.where(menu_id: milanesa.family_ids, date: Date.current..).pluck(:date))
      .to eq([ last_publishable ])
  end

  # Criterio 2, límites: el calendario habilita los días hábiles desde hoy hasta
  # el último publicable, y nada más. Cada caso falla por una sola razón.
  it "no habilita días pasados, fines de semana ni fechas fuera del período de publicación" do
    visit_hydrated edit_provider_menu_path(milanesa)

    choose_weekday("Martes")

    expect(date_disabled?("#agenda-date", monday - 3)).to be(true)     # hábil, pero pasado
    expect(date_disabled?("#agenda-date", monday + 5)).to be(true)     # sábado
    expect(date_disabled?("#agenda-date", friday)).to be(false)        # último hábil de la semana
    expect(date_disabled?("#agenda-date", Calendar.new.maximum_publish_date + 3)).to be(true)
  end

  # Criterio 2: cambiar de día mueve la fecha elegida con él.
  it "cambia la fecha cuando se elige otro día de la semana" do
    visit_hydrated edit_provider_menu_path(milanesa)

    choose_weekday("Martes")
    choose_weekday("Miércoles")

    fill_name("Milanesa napolitana")
    apply_to_saved_dish

    expect(page).to have_content("¡Plato modificado!")

    expect(Schedule.where(menu_id: milanesa.family_ids, date: Date.current..).pluck(:date))
      .to eq([ wednesday ])
  end

  # Criterio 2: el mismo plato se ve desde el menú del empleado el día elegido y
  # no los demás.
  it "el empleado ve el plato solo el día elegido" do
    visit_hydrated edit_provider_menu_path(milanesa)

    choose_weekday("Martes")
    fill_name("Milanesa napolitana")
    apply_to_saved_dish
    expect(page).to have_content("¡Plato modificado!")

    sign_out
    sign_in users(:one), role: :consumer

    visit_hydrated dashboard_path
    within("[role=radiogroup]") { find("[role=radio]", text: /\b#{tuesday.day}\b/).click }
    expect(page).to have_content("Milanesa napolitana")

    within("[role=radiogroup]") { find("[role=radio]", text: /\b#{wednesday.day}\b/).click }
    expect(page).to have_no_content("Milanesa napolitana")
  end
end
