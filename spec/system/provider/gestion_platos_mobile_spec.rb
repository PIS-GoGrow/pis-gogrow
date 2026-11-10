# frozen_string_literal: true

require "rails_helper"

# Historia del proveedor: "Quiero tener una gestión de platos y schedules desde
# la aplicación mobile", criterios 1 a 4.
#
# La gestión en escritorio ya está cubierta por editar_plato_publicado_spec.rb,
# editar_plato_programado_spec.rb, seleccionar_fecha_unica_spec.rb,
# eliminar_plato_guardado_spec.rb y quitar_plato_spec.rb. Lo que se recorre acá es
# la misma gestión desde el celular: la barra de acciones fija sobre la
# navegación inferior, los días de la semana y las hojas (sheets) de confirmación
# son los que cambian de forma a 375 px.
RSpec.describe "Gestión de platos y menú desde el celular del proveedor" do
  fixtures :users, :providers, :menus, :schedules, :orders, :consumers, :companies

  # Un lunes futuro: "hoy" es un día hábil y la semana que se abre es la que el
  # proveedor puede publicar, así las fechas no dependen del día en que corre la
  # suite.
  around do |example|
    travel_to(Date.current.next_occurring(:monday).noon) { example.run }
  end

  let(:provider) { providers(:tuviandita) }
  let(:provider_user) { users(:provider_user) }
  let(:milanesa) { menus(:milanesa) }
  let(:monday) { Date.current }
  let(:tuesday) { Date.current + 1.day }
  let(:wednesday) { Date.current + 2.days }

  before do
    page.current_window.resize_to(375, 667)
    Order.destroy_all
    Schedule.destroy_all
    sign_in provider_user, role: :provider
  end

  after do
    page.current_window.resize_to(1400, 1400)
  end

  def publish(menu, date)
    menu.schedules.create!(date:)
  end

  def open_schedules(tab: nil)
    visit_hydrated schedules_path(tab: tab)
    without_animations
  end

  # El link navega por Inertia: hasta que React no hidrata la página nueva, la
  # pestaña "Platos guardados" todavía no tiene handler y el clic se pierde.
  def open_new_dishes
    click_link "Agregar platos"
    wait_for_hydration
    without_animations
  end

  # Los días de la semana son los radios de WeekDayTabs; el número del día
  # alcanza para distinguirlos dentro de la semana.
  def day_tab(date)
    within("[role=radiogroup]") { find("[role=radio]", text: /\b#{date.day}\b/) }
  end

  def select_day(date)
    day_tab(date).click
  end

  def dish_card(name)
    find("[data-slot=card]", text: name)
  end

  # Criterio 4: qué platos hay publicados en cada día de la semana.
  it "muestra qué platos hay publicados en cada día de la semana" do
    tarta = Menu.create!(provider:, name: "Tarta de verduras", description: "Con masa integral", price: 280)
    publish(milanesa, monday)
    publish(tarta, tuesday)

    open_schedules

    # Los días con menú se anuncian desde la tira de días, y el vacío también.
    expect(day_tab(monday)).to have_text("Publicado")
    expect(day_tab(tuesday)).to have_text("Publicado")
    expect(day_tab(wednesday)).to have_no_text("Publicado")

    # La semana abre en hoy (lunes) y muestra los platos de ese día.
    expect(page).to have_content(milanesa.name)

    select_day(tuesday)
    expect(page).to have_content(tarta.name)
    expect(page).to have_no_content(milanesa.name)

    select_day(wednesday)
    expect(page).to have_content("No tenés platos publicados para el #{DateFormat.long(wednesday, inline: true)}")
  end

  # Criterio 2: publicar platos en una fecha elegida por el proveedor.
  it "publica un plato guardado en la fecha que elige desde el celular" do
    open_schedules
    select_day(tuesday)

    # La barra de acciones del día abre el formulario con esa fecha ya elegida.
    open_new_dishes

    click_on "Platos guardados"
    click_on "Platos guardados" unless page.has_content?("¿Para qué fecha vas a agregar platos?", wait: 2)
    expect(page).to have_content("¿Para qué fecha vas a agregar platos?")
    expect(find("#saved-date")).to have_text(DateFormat.long(tuesday))

    click_button "Agregar #{milanesa.name} a la selección"
    click_button "Agregar", exact: true

    expect(page).to have_content("¡Plato agregado!")
    expect(page).to have_content(
      "Tu plato fue agregado al menú del #{DateFormat.long(tuesday, inline: true)} correctamente."
    )

    click_link "Volver a Menú"

    # Vuelve al día publicado, con el plato ya en el menú.
    expect(page).to have_current_path(schedules_path(date: tuesday.iso8601))
    expect(page).to have_content(milanesa.name)
    expect(Schedule.find_by(menu: milanesa, date: tuesday)).to be_present
  end

  # Criterio 1: editar un plato ya publicado.
  it "edita un plato ya publicado desde el celular y el día queda con el nombre nuevo" do
    publish(milanesa, monday)
    open_schedules

    # El plato del día es el punto de entrada a la edición en mobile.
    click_link "Editar #{milanesa.name}"
    wait_for_hydration

    expect(page).to have_field("name", with: milanesa.name)
    fill_in "name", with: "Milanesa napolitana", fill_options: { clear: :backspace }
    click_button "Modificar"

    find("label", text: "Modificar el plato guardado").click
    click_button "Aplicar cambios"

    expect(page).to have_content("¡Plato modificado!")
    expect(milanesa.reload.name).to eq("Milanesa napolitana")

    click_link "Listo"

    # Vuelve al mismo día del menú, ya con el nombre nuevo.
    expect(page).to have_current_path(schedules_path, ignore_query: true)
    expect(day_tab(monday)[:"data-state"]).to eq("on")
    expect(page).to have_content("Milanesa napolitana")
    expect(page).to have_no_content("Milanesa con papas fritas")
  end

  # Criterio 3: eliminar un plato ya subido.
  it "elimina un plato guardado desde el celular y avisa que se puede volver a crear" do
    tarta = Menu.create!(provider:, name: "Tarta de jamón y queso", description: "De masa integral", price: 300)

    open_schedules(tab: "saved")

    within(dish_card(tarta.name)) { click_button "Eliminar" }
    within("[role=dialog]") do
      expect(page).to have_content("¿Eliminar plato guardado?")
      click_button "Eliminar"
    end

    expect(page).to have_content("Plato eliminado")
    expect(page).to have_content("El plato se eliminó de tus platos guardados. Podés volver a crearlo cuando quieras.")

    click_button "Listo"

    expect(page).to have_no_content(tarta.name)
    # No se borra de la base: se archiva para no perder el historial de pedidos.
    expect(tarta.reload.archived_at).to be_present
  end
end
