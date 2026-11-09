# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Contador de cantidad y botón quitar en el carrito del consumidor", type: :system do
  fixtures :users, :consumers, :companies, :providers, :menus,
           :benefit_configurations, :benefits

  let(:monday) { Date.current.beginning_of_week(:monday) }
  let(:milanesa) { menus(:milanesa) }

  around do |example|
    travel_to(Date.current.next_occurring(:monday).noon) { example.run }
  end

  before do
    OrderBenefit.delete_all
    OrderAccount.delete_all
    Order.delete_all
    Schedule.delete_all

    # Stock limitado a 3 unidades para probar tope de stock
    Schedule.create!(menu: milanesa, date: monday, amount: 3)

    page.current_window.resize_to(1400, 1400)
    sign_in users(:one), role: :consumer
  end

  after do
    page.current_window.resize_to(1400, 1400)
  end

  def add_milanesa_to_cart
    visit_hydrated dashboard_path
    click_button "Agregar Milanesa con papas fritas"
    expect(page).to have_content("Notas para este plato")
    click_button "Agregar"
    click_link "Ver carrito"
    expect(page).to have_content("Tu carrito")
  end

  it "permite aumentar la cantidad, respeta el stock máximo y genera el pedido con la cantidad editada" do
    add_milanesa_to_cart

    # Cantidad inicial 1: el botón '-' se muestra como tacho con label 'Quitar <nombre>'
    expect(page).to have_content("Milanesa con papas fritas x1")
    expect(page).to have_button("Quitar Milanesa con papas fritas")

    # Aumentar a 2: el botón '-' pasa a ser 'Quitar una unidad de <nombre>'
    click_button "Agregar una unidad de Milanesa con papas fritas"
    expect(page).to have_content("Milanesa con papas fritas x2")
    expect(page).to have_button("Quitar una unidad de Milanesa con papas fritas")
    expect(page).to have_no_button("Quitar Milanesa con papas fritas")

    # Aumentar a 3 (máximo de stock disponible): el botón '+' queda deshabilitado
    click_button "Agregar una unidad de Milanesa con papas fritas"
    expect(page).to have_content("Milanesa con papas fritas x3")
    expect(page).to have_button("Agregar una unidad de Milanesa con papas fritas", disabled: true)

    # Reducir a 2 y confirmar el pedido
    click_button "Quitar una unidad de Milanesa con papas fritas"
    expect(page).to have_content("Milanesa con papas fritas x2")
    expect(page).to have_button("Agregar una unidad de Milanesa con papas fritas", disabled: false)

    click_button "Confirmar pedido"
    expect(page).to have_content("¡Pedido recibido!")

    # Integridad en base de datos: el pedido se persistió con cantidad 2
    expect(Order.count).to eq(1)
    expect(Order.last.amount).to eq(2)
  end

  it "elimina el plato del carrito al presionar el ícono de tacho cuando la cantidad es 1" do
    add_milanesa_to_cart

    expect(page).to have_content("Milanesa con papas fritas x1")
    click_button "Quitar Milanesa con papas fritas"

    expect(page).to have_content("Todavía no agregaste platos.")
    expect(page).to have_no_content("Milanesa con papas fritas")
  end

  it "al tocar un plato ya agregado abre la pantalla en modo modificación, permite editar la cantidad y guardar" do
    visit_hydrated dashboard_path
    click_button "Agregar Milanesa con papas fritas"
    expect(page).to have_content("Notas para este plato")
    fill_in "notes", with: "Sin sal"
    click_button "Agregar"

    # En el menú semanal, el plato aparece con badge Agregado y cantidad 1
    expect(page).to have_content("Agregado")
    expect(page).to have_button("Agregar Milanesa con papas fritas", text: "1")

    # Al volver a tocar el plato agregado, abre el detalle con los datos precargados y botón 'Modificar'
    click_button "Agregar Milanesa con papas fritas"
    expect(page).to have_content("Agregado")
    expect(page).to have_field("notes", with: "Sin sal")
    expect(page).to have_button("Modificar", exact: true)
    expect(page).to have_no_button("Agregar", exact: true)

    # Contador muestra el tacho al estar en 1 (aria-label 'Quitar')
    expect(page).to have_button("Quitar", exact: true)

    # Aumentar a 2: el botón '-' ya no es tacho, sino 'Quitar uno'
    click_button "Agregar uno"
    expect(page).to have_button("Quitar uno", exact: true)
    expect(page).to have_no_button("Quitar", exact: true)

    # Guardar cambios
    click_button "Modificar", exact: true

    # Vuelve al menú y el contador del plato muestra 2
    expect(page).to have_content("Agregado")
    expect(page).to have_button("Agregar Milanesa con papas fritas", text: "2")

    # Ir al carrito y confirmar el pedido con cantidad 2 y notas modificadas
    click_link "Ver carrito"
    expect(page).to have_content("Milanesa con papas fritas x2")
    click_button "Confirmar pedido"
    expect(page).to have_content("¡Pedido recibido!")
    expect(Order.last.amount).to eq(2)
    expect(Order.last.notes).to eq("Sin sal")
  end

  it "elimina el plato del carrito y vuelve al menú al presionar el tacho de basura en el detalle del plato agregado" do
    visit_hydrated dashboard_path
    click_button "Agregar Milanesa con papas fritas"
    click_button "Agregar"

    expect(page).to have_content("Agregado")

    # Abrir el plato agregado
    click_button "Agregar Milanesa con papas fritas"
    expect(page).to have_button("Modificar", exact: true)

    # Presionar el tacho de basura
    click_button "Quitar", exact: true

    # Vuelve al menú y el plato ya no está en el carrito
    expect(page).to have_content("Menú semanal")
    expect(page).to have_no_content("Agregado")
    expect(page).to have_button("Agregar Milanesa con papas fritas", text: "")
    expect(page).to have_content("0 platos")
  end
end
