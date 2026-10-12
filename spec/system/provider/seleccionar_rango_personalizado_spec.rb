# frozen_string_literal: true

require "rails_helper"

# Historia IBP-050, criterio 3: "Como proveedor debo poder seleccionar un rango
# personalizado para elegir desde cuánto hasta cuándo estará disponible un plato".
#
# Un rango no edita el plato guardado: crea una variante que manda solo entre las
# dos fechas y, después, el plato vuelve a su configuración anterior. Por eso lo
# que se verifica acá es qué queda sirviendo cada día.
#
# TODO(defecto): falta corregir Menus::Update#carve antes de poder testear la
# re-edición de un rango por encima de otro. Al guardar un rango nuevo sobre un
# plato que ya tenía uno, la variante anterior se recorta bien pero los días que
# quedan dentro del rango nuevo siguen apuntando a ella, así que el empleado ve el
# plato viejo en días que el proveedor acaba de cambiar. El ejemplo que cubría
# esto se agregó a este archivo en cuanto se corrija. Historia: IBP-050, criterio
# 3. Defecto: docs/reports/defects/DEFECT-carve-no-devuelve-programaciones-al-plato-guardado-11-10-2026.md
RSpec.describe "Seleccionar un rango personalizado de disponibilidad" do
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
  let(:thursday) { Date.current + 3 }
  let(:friday) { Date.current + 4 }

  before do
    Order.destroy_all
    Schedule.destroy_all
    sign_in users(:provider_user), role: :provider
  end

  # Publica el plato de lunes a viernes, como si el proveedor ya lo tuviera con
  # una agenda semanal.
  def publish_week
    milanesa.agendas.create!(weekdays: [ 1, 2, 3, 4, 5 ], starts_on: monday, amount: 10)
    Menus::AgendaScheduler.call(milanesa)
  end

  def fill_name(value)
    fill_in "name", with: value, fill_options: { clear: :backspace }
  end

  # Pasa al rango con exactamente los días indicados marcados. Si el formulario
  # abre con una agenda semanal ya cargada, el toggle arranca con lunes a viernes
  # marcados.
  def choose_ranged_weekdays(*names)
    set_weekdays(*names)
    switch_to_range
  end

  def switch_to_range
    find("label", text: "Repetir en un rango personalizado").click
    expect(find("#agenda-starts-on")).to be_present
  end

  def choose_dates(from, to)
    pick_date "#agenda-starts-on", from
    pick_date "#agenda-ends-on", to, opens_at: from
  end

  def dish_name_on(date)
    Schedule.find_by!(menu_id: milanesa.family_ids, date:).menu.name
  end

  # Criterio 3
  it "sirve el plato cambiado solo dentro del rango y vuelve al guardado después" do
    publish_week

    visit_hydrated edit_provider_menu_path(milanesa)
    choose_ranged_weekdays "Martes", "Miércoles", "Jueves"
    choose_dates tuesday, thursday

    fill_name("Milanesa napolitana")
    click_button "Modificar"

    expect(page).to have_content("¿Aplicar cambios durante este período?")
    expect(page).to have_content("Después, el plato volverá automáticamente a su configuración anterior.")

    click_button "Aplicar cambios"
    expect(page).to have_content("¡Plato modificado!")

    # El plato guardado no se toca: el rango vive en una variante aparte.
    expect(milanesa.reload.name).to eq("Milanesa con papas fritas")
    variant = milanesa.variants.sole
    expect(variant.name).to eq("Milanesa napolitana")
    expect(variant).to have_attributes(valid_from: tuesday, valid_until: thursday)

    expect(dish_name_on(monday)).to eq("Milanesa con papas fritas")
    expect(dish_name_on(tuesday)).to eq("Milanesa napolitana")
    expect(dish_name_on(wednesday)).to eq("Milanesa napolitana")
    expect(dish_name_on(thursday)).to eq("Milanesa napolitana")
    expect(dish_name_on(friday)).to eq("Milanesa con papas fritas")
  end

  # Criterio 3, límite: el rango más corto que la aplicación acepta es un solo
  # día, con la fecha de fin igual a la de inicio.
  it "acepta un rango de un solo día" do
    publish_week

    visit_hydrated edit_provider_menu_path(milanesa)
    choose_ranged_weekdays "Martes"
    choose_dates tuesday, tuesday

    fill_name("Milanesa napolitana")
    click_button "Modificar"
    expect(page).to have_content("¿Aplicar cambios durante este período?")
    click_button "Aplicar cambios"
    expect(page).to have_content("¡Plato modificado!")

    variant = milanesa.variants.sole
    expect(variant).to have_attributes(valid_from: tuesday, valid_until: tuesday)

    expect(dish_name_on(tuesday)).to eq("Milanesa napolitana")
    expect(dish_name_on(wednesday)).to eq("Milanesa con papas fritas")
  end

  # Criterio 3, límites: la fecha de fin no puede ser anterior a la de inicio, así
  # que el calendario de "Hasta" no habilita días previos al de "Desde".
  it "no habilita en la fecha de fin un día anterior a la de inicio" do
    visit_hydrated edit_provider_menu_path(milanesa)
    choose_ranged_weekdays "Martes"
    choose_dates tuesday, thursday

    expect(date_disabled?("#agenda-ends-on", monday)).to be(true)
    expect(date_disabled?("#agenda-ends-on", tuesday)).to be(false)
    expect(date_disabled?("#agenda-ends-on", thursday)).to be(false)
  end

  # El escenario de re-editar un rango por encima de otro ("recorta el rango
  # anterior al editar encima de él") está en el TODO(defecto) de la cabecera:
  # la app recorta la variante vieja pero deja sus programaciones en los días del
  # rango nuevo. Va a este archivo apenas se corrija Menus::Update#carve.
end
