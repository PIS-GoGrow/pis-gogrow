# frozen_string_literal: true

require "rails_helper"

# Historia IBP-089: "Como PROVEEDOR, quiero poder crear/editar menús desde la
# aplicación MOBILE", criterio 2: editar un plato ya creado y que el plato
# editado se le muestre a los consumidores desde el celular.
#
# La edición del proveedor y su reflejo en el menú del empleado ya se cubren por
# separado en editar_plato_publicado_spec.rb, pero a 1400 px. Acá se recorre el
# circuito completo a 375 px: proveedor edita desde su pantalla mobile y el
# consumidor ve los datos nuevos en su menú mobile.
RSpec.describe "Editar un plato desde el celular y verlo como consumidor" do
  fixtures :users, :providers, :menus, :schedules, :consumers, :companies

  around do |example|
    travel_to(Date.current.next_occurring(:monday).noon) { example.run }
  end

  let(:provider) { providers(:tuviandita) }
  let(:provider_user) { users(:provider_user) }
  let(:milanesa) { menus(:milanesa) }
  let(:monday) { Date.current }

  before do
    page.current_window.resize_to(375, 667)
    Order.destroy_all
    Schedule.delete_all
    Schedule.create!(menu: milanesa, date: monday)
    sign_in provider_user, role: :provider
  end

  after do
    page.current_window.resize_to(1400, 1400)
  end

  def edit_from_mobile
    visit_hydrated schedules_path
    without_animations
    click_link "Editar #{milanesa.name}"
    wait_for_hydration
    without_animations
  end

  def open_consumer_menu
    visit_hydrated dashboard_path
    without_animations
    within("[role=radiogroup]") { find("[role=radio]", text: /\b#{monday.day}\b/).click }
  end

  it "muestra al consumidor mobile el plato con el nombre, la descripción y el precio nuevos" do
    edit_from_mobile

    expect(page).to have_field("name", with: milanesa.name)
    fill_in "name", with: "Milanesa napolitana", fill_options: { clear: :backspace }
    fill_in "description", with: "Con papas rústicas", fill_options: { clear: :backspace }
    fill_in "price", with: "410", fill_options: { clear: :backspace }

    click_button "Modificar"
    find("label", text: "Modificar el plato guardado").click
    click_button "Aplicar cambios"

    expect(page).to have_content("¡Plato modificado!")
    expect(milanesa.reload).to have_attributes(
      name: "Milanesa napolitana",
      description: "Con papas rústicas",
      price: 410.0
    )

    click_link "Listo"
    sign_out
    sign_in users(:one), role: :consumer

    open_consumer_menu

    expect(page).to have_content("Milanesa napolitana")
    expect(page).to have_content("Con papas rústicas")
    expect(page).to have_content("$410")
    expect(page).to have_no_content("Milanesa con papas fritas")

    # Persistencia: el consumidor sigue viendo el plato nuevo después de recargar.
    refresh
    expect(page).to have_content("Milanesa napolitana")
  end

  it "no cambia el plato del consumidor si el proveedor no confirma la edición" do
    edit_from_mobile

    fill_in "name", with: "Milanesa napolitana", fill_options: { clear: :backspace }
    click_button "Modificar"
    find("label", text: "Modificar el plato guardado").click
    click_button "Volver"

    expect(milanesa.reload.name).to eq("Milanesa con papas fritas")

    sign_out
    sign_in users(:one), role: :consumer

    open_consumer_menu

    expect(page).to have_content("Milanesa con papas fritas")
    expect(page).to have_no_content("Milanesa napolitana")
  end
end
