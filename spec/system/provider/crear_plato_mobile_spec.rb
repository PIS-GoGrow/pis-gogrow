# frozen_string_literal: true

require "rails_helper"

# Historia IBP-089: "Como PROVEEDOR, quiero poder crear/editar menús desde la
# aplicación MOBILE", criterio 1: crear platos desde el celular.
#
# El alta en escritorio ya está cubierta por reset_formulario_plato_spec.rb,
# validaciones_formulario_plato_spec.rb, grupos_opciones_requeridos_spec.rb y
# pedido_de_punta_a_punta_spec.rb. Acá se recorre el mismo alta a 375 px, que es
# donde el formulario, la agenda y el cartel de confirmación cambian de forma.
RSpec.describe "Crear un plato desde el celular del proveedor" do
  fixtures :users, :providers, :menus, :schedules

  # Un lunes futuro: el alta arranca con "hoy" elegido y la agenda queda dentro
  # de la semana publicable, sin depender del día en que corre la suite.
  around do |example|
    travel_to(Date.current.next_occurring(:monday).noon) { example.run }
  end

  let(:provider) { providers(:tuviandita) }
  let(:provider_user) { users(:provider_user) }
  let(:monday) { Date.current }

  before do
    page.current_window.resize_to(375, 667)
    Order.destroy_all
    Schedule.delete_all
    sign_in provider_user, role: :provider
  end

  after do
    page.current_window.resize_to(1400, 1400)
  end

  # Entra por la navegación mobile, no por URL directa: el criterio habla de la
  # aplicación mobile, así que el recorrido incluye llegar a la pantalla.
  def open_new_dishes
    visit_hydrated schedules_path
    without_animations
    click_link "Agregar platos"
    wait_for_hydration
    without_animations
  end

  def fill_dish(name:, description:, price:)
    fill_in "name", with: name
    fill_in "description", with: description
    fill_in "price", with: price
  end

  it "crea un plato nuevo y lo deja publicado en el día que propone el alta" do
    open_new_dishes

    fill_dish(name: "Wok de verduras", description: "Con arroz integral", price: "320")
    find('button[type="submit"]', text: "Agregar", exact_text: true).click

    expect(page).to have_content("¡Plato agregado!")

    menu = provider.menus.find_by(name: "Wok de verduras")
    expect(menu).to have_attributes(description: "Con arroz integral", price: 320.0)
    expect(menu.schedules.find_by(date: monday)).to be_present

    click_link "Volver a Menú"

    expect(page).to have_current_path(schedules_path(date: monday.iso8601))
    expect(page).to have_content("Wok de verduras")
  end

  it "no guarda el plato si falta el nombre, la descripción o el precio" do
    open_new_dishes

    expect do
      find('button[type="submit"]', text: "Agregar", exact_text: true).click
      expect(page).to have_css("[data-invalid=true]", count: 3)
      expect(page).to have_content("No puede estar vacío.", count: 3)
    end.not_to change(Menu, :count)
  end

  it "no guarda el plato con un nombre de solo espacios" do
    open_new_dishes

    fill_dish(name: "   ", description: "Con arroz integral", price: "320")

    expect do
      find('button[type="submit"]', text: "Agregar", exact_text: true).click
      expect(page).to have_content("No puede estar vacío.")
    end.not_to change(Menu, :count)
  end

  it "no guarda el plato con precio cero ni negativo" do
    [ "0", "-10" ].each do |price|
      open_new_dishes

      fill_dish(name: "Wok de verduras", description: "Con arroz integral", price:)

      expect do
        find('button[type="submit"]', text: "Agregar", exact_text: true).click
        expect(page).to have_content("Tiene que ser mayor que 0.")
      end.not_to change(Menu, :count)
    end
  end
end
