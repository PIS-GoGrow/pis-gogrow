# frozen_string_literal: true

require "rails_helper"

# Historia IBP-050, criterio 1: "Como proveedor debo poder editar los platos que
# ya he publicado".
#
# Lo de "modificar solo para este día" vive en editar_plato_programado_spec.rb.
# Acá va lo que abre esa pantalla: cambiar el plato guardado, y qué pasa con lo
# que ya estaba programado y con los pedidos que ya existen.
RSpec.describe "Editar un plato que ya está publicado" do
  fixtures :users, :providers, :menus, :schedules, :consumers, :companies

  # Se viaja a un lunes futuro: hoy siempre es un día hábil y la semana que ve el
  # empleado es la misma que el proveedor puede publicar (lunes a viernes), así
  # las fechas del ejemplo no dependen de qué día corrió la suite.
  around do |example|
    travel_to(Date.current.next_occurring(:monday).noon) { example.run }
  end

  let(:milanesa) { menus(:milanesa) }
  let(:monday) { Date.current }
  let(:friday) { Date.current + 4 }

  before do
    # Cada ejemplo declara la programación que necesita. Las fechas de los
    # fixtures son relativas a Date.current y no sobreviven al viaje de tiempo.
    Order.destroy_all
    Schedule.destroy_all
    sign_in users(:provider_user), role: :provider
  end

  def publish(menu, date, amount: 10)
    Schedule.create!(menu:, date:, amount:)
  end

  def confirmed_order(schedule)
    Order.create!(
      consumer: consumers(:one),
      schedule:,
      status: :confirmed,
      amount: 1,
      price: schedule.menu.price,
      delivery_method: :office
    )
  end

  def fill_name(value)
    fill_in "name", with: value, fill_options: { clear: :backspace }
  end

  def apply_to_saved_dish
    click_button "Modificar"
    find("label", text: "Modificar el plato guardado").click
    click_button "Aplicar cambios"
  end

  # Criterio 1
  it "aplica los cambios al plato guardado y deja ese día apuntando al plato guardado" do
    schedule = publish(milanesa, friday)
    order = confirmed_order(schedule)

    visit_hydrated edit_provider_menu_path(milanesa, schedule_id: schedule.id)

    expect(page).to have_field("name", with: milanesa.name)

    fill_name("Milanesa napolitana")
    click_button "Modificar"

    find("label", text: "Modificar el plato guardado").click
    click_button "Continuar"
    find("label", text: "Mantener los pedidos confirmados").click
    click_button "Aplicar cambios"

    expect(page).to have_content("¡Plato modificado!")

    expect(milanesa.reload.name).to eq("Milanesa napolitana")
    expect(schedule.reload.menu).to eq(milanesa)

    # El pedido se mantiene y sigue mostrando el plato que se pidió, no el nuevo.
    expect(order.reload).to be_confirmed
    expect(order.menu_name).to eq("Milanesa con papas fritas")
  end

  # Criterio 1
  it "deja los días programados antes del cambio con la versión anterior del plato" do
    earlier = publish(milanesa, monday)
    later = publish(milanesa, friday)

    visit_hydrated edit_provider_menu_path(milanesa, schedule_id: later.id)

    fill_name("Milanesa napolitana")
    apply_to_saved_dish

    expect(page).to have_content("¡Plato modificado!")

    expect(milanesa.reload.name).to eq("Milanesa napolitana")
    expect(later.reload.menu).to eq(milanesa)

    # Lo publicado antes del corte conserva el plato anterior.
    expect(earlier.reload.menu.name).to eq("Milanesa con papas fritas")
    expect(earlier.menu.base_menu).to eq(milanesa)
  end

  # Criterio 1
  it "rechaza los pedidos confirmados del día cuando el proveedor lo elige" do
    schedule = publish(milanesa, friday)
    order = confirmed_order(schedule)

    visit_hydrated edit_provider_menu_path(milanesa, schedule_id: schedule.id)

    fill_name("Milanesa napolitana")
    click_button "Modificar"
    find("label", text: "Modificar el plato guardado").click
    click_button "Continuar"
    find("label", text: "Rechazar los pedidos confirmados").click
    click_button "Aplicar cambios"

    expect(page).to have_content("¡Plato modificado!")

    expect(milanesa.reload.name).to eq("Milanesa napolitana")
    expect(order.reload).to be_rejected
    expect(order).to be_rejection_reason_dish_modified
  end

  # Criterio 1
  it "edita un plato guardado que todavía no tiene fechas sin programarlo" do
    visit_hydrated edit_provider_menu_path(milanesa)

    fill_name("Milanesa de la casa")
    click_button "Modificar"

    expect(page).to have_content("¿Modificar el plato guardado?")
    expect(page).to have_content("Este plato se modificará en tus platos guardados.")

    click_button "Aplicar cambios"

    expect(page).to have_content("¡Plato modificado!")

    expect(milanesa.reload.name).to eq("Milanesa de la casa")
    expect(milanesa.schedules).to be_empty
    expect(milanesa.agendas).to be_empty
  end

  # Criterio 1: editar no es solo el nombre; el precio y la descripción también se
  # guardan y el día programado sigue sirviendo el plato guardado.
  it "guarda el precio y la descripción nuevos del plato guardado" do
    schedule = publish(milanesa, friday)

    visit_hydrated edit_provider_menu_path(milanesa, schedule_id: schedule.id)

    fill_in "price", with: "410.50", fill_options: { clear: :backspace }
    fill_in "description", with: "Con papas rústicas", fill_options: { clear: :backspace }
    apply_to_saved_dish

    expect(page).to have_content("¡Plato modificado!")

    expect(milanesa.reload.price).to eq(410.50)
    expect(milanesa.description).to eq("Con papas rústicas")
    expect(schedule.reload.menu).to eq(milanesa)
  end

  # Criterio 1: los tres datos del plato son obligatorios y el formulario los valida
  # en el cliente. Lo observable es que avisa y no manda el PATCH: el plato y su
  # programación quedan intactos.
  context "cuando falta un dato obligatorio del plato" do
    let(:schedule) { publish(milanesa, friday) }

    before { visit_hydrated edit_provider_menu_path(milanesa, schedule_id: schedule.id) }

    {
      "el nombre" => "name",
      "el precio" => "price",
      "la descripción" => "description"
    }.each do |label, field|
      it "no guarda si falta #{label}" do
        fill_in field, with: "", fill_options: { clear: :backspace }
        click_button "Modificar"

        expect(page).to have_content("No puede estar vacío.")
        expect(milanesa.reload.name).to eq("Milanesa con papas fritas")
        expect(schedule.reload.menu).to eq(milanesa)
      end
    end
  end

  # Control de acceso: la pantalla es del namespace del proveedor y el plato es de
  # un proveedor concreto. Ninguno de los dos se esquiva por URL.
  context "control de acceso" do
    it "no deja editar el plato de otro proveedor" do
      sign_in users(:other_provider_user), role: :provider

      # Sin visit_hydrated: el server rechaza con RecordNotFound y lo que se
      # renderiza es la página de excepción de Rails, que no monta la app.
      visit edit_provider_menu_path(milanesa)

      # El server rechaza el acceso, así que el formulario nunca llega a
      # renderizarse. El status 404 en sí lo cubre el request spec: el driver de
      # Selenium no lo expone y el entorno de test muestra la página de excepción
      # en vez de la de errores.
      expect(page).to have_no_field("name")
      expect(page).to have_no_content("Agenda")
      expect(milanesa.reload.name).to eq("Milanesa con papas fritas")
    end

    it "no deja entrar a un empleado por URL directa" do
      sign_in users(:one), role: :consumer

      visit_hydrated edit_provider_menu_path(milanesa)

      expect(page).to have_no_current_path(edit_provider_menu_path(milanesa))
      expect(page).to have_content("No tenés permiso para acceder a este recurso.")
      expect(page).to have_no_field("name")
    end

    it "redirige al inicio de sesión a un usuario sin autenticar" do
      sign_out

      visit_hydrated edit_provider_menu_path(milanesa)

      expect(page).to have_current_path(sign_in_path)
    end
  end

  # El mismo plato se ve desde el menú del empleado: el nombre tiene que coincidir
  # en las dos pantallas.
  it "el empleado ve en su menú el plato con el nombre actualizado" do
    schedule = publish(milanesa, friday)

    visit_hydrated edit_provider_menu_path(milanesa, schedule_id: schedule.id)

    fill_name("Milanesa napolitana")
    apply_to_saved_dish
    expect(page).to have_content("¡Plato modificado!")

    sign_out
    sign_in users(:one), role: :consumer

    visit_hydrated dashboard_path
    within("[role=radiogroup]") { find("[role=radio]", text: /\b#{friday.day}\b/).click }

    expect(page).to have_content("Milanesa napolitana")
    expect(page).to have_no_content("Milanesa con papas fritas")
  end
end
