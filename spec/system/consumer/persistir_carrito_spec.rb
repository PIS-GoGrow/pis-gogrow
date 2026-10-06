# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Persistir carrito del consumidor", type: :system do
  fixtures :users, :consumers, :companies, :providers, :menus, :benefit_configurations, :benefits

  let(:monday) { Date.current.beginning_of_week(:monday) }

  around do |example|
    travel_to(Date.current.next_occurring(:monday).beginning_of_day + 10.hours) { example.run }
  end

  before do
    OrderBenefit.delete_all
    OrderAccount.delete_all
    Order.delete_all
    Schedule.delete_all
    publish(menus(:milanesa))
    sign_in users(:one), role: :consumer
  end

  def publish(menu, date = monday, amount: 10)
    Schedule.create!(menu:, date:, amount:)
  end

  def add_milanesa_to_cart
    visit dashboard_path
    expect(page).to have_content("Milanesa con papas fritas")

    click_button "Agregar Milanesa con papas fritas"
    expect(page).to have_content("Notas para este plato")
    click_button "Agregar"

    first(:button, "Ver carrito").click
    expect(page).to have_content("Tu carrito")
    expect(page).to have_content("Milanesa con papas fritas x1")
  end

  it "mantiene los platos del carrito y sus datos al recargar la página" do
    add_milanesa_to_cart

    # Recargamos la página completa en el navegador
    visit dashboard_path

    # El carrito en sessionStorage debe conservar la selección
    first(:button, "Ver carrito").click
    expect(page).to have_content("Tu carrito")
    expect(page).to have_content("Milanesa con papas fritas x1")

    # Verificamos que el contenido reside en sessionStorage
    stored_cart = page.evaluate_script("sessionStorage.getItem('cart')")
    expect(stored_cart).to include("Milanesa con papas fritas")
  end

  it "mantiene los platos del carrito al navegar a otra pantalla de la app y regresar al menú" do
    add_milanesa_to_cart

    # Navegamos a otra sección (Mis pedidos)
    visit orders_path
    expect(page).to have_content("Mis pedidos")

    # Regresamos al menú del día / dashboard
    visit dashboard_path

    first(:button, "Ver carrito").click
    expect(page).to have_content("Tu carrito")
    expect(page).to have_content("Milanesa con papas fritas x1")
  end

  it "vacía el carrito y limpia sessionStorage cuando el pedido se confirma con éxito" do
    add_milanesa_to_cart

    click_button "Confirmar pedido"
    expect(page).to have_content("¡Pedido recibido!")
    expect(page).to have_content("Milanesa con papas fritas")

    # Al volver al dashboard, el carrito debe estar vacío
    visit dashboard_path

    stored_cart = page.evaluate_script("sessionStorage.getItem('cart')")
    expect(stored_cart).to eq("[]")

    expect(page).to have_no_button("Ver carrito")
  end

  it "actualiza el sessionStorage al eliminar un plato del carrito manualmente" do
    add_milanesa_to_cart

    click_button "Quitar Milanesa con papas fritas"
    expect(page).to have_content("Todavía no agregaste platos.")

    # Al recargar la página, persiste vacío
    visit dashboard_path
    stored_cart = page.evaluate_script("sessionStorage.getItem('cart')")
    expect(stored_cart).to eq("[]")
  end
end
