# frozen_string_literal: true

require "rails_helper"

# IBP-022 — Como EMPLEADO, quiero seleccionar las opciones de personalización que el
# plato admita al momento de pedir, para recibir la vianda según mi preferencia.
#
# Chequeo transversal de consistencia entre vistas: lo que el proveedor prepara en
# el plato tiene que ser exactamente lo que el empleado puede elegir, y lo que el
# proveedor recibe en el pedido tiene que ser lo que el empleado eligió.
RSpec.describe "Ver la personalización del pedido", type: :system do
  fixtures :users, :consumers, :companies, :providers, :menus, :menu_option_groups

  around do |example|
    travel_to(Date.current.next_occurring(:monday).noon) { example.run }
  end

  let(:monday) { Date.current.beginning_of_week(:monday) }
  let(:menu) { menus(:sorrentinos) }
  let(:salsa) { menu.option_groups.find_by!(name: "Salsa") }
  let(:relleno) { menu.option_groups.find_by!(name: "Relleno") }

  let(:schedule) { Schedule.create!(menu:, date: monday, amount: 10) }

  def order_with(values:, notes: nil)
    Order.create!(
      consumer: consumers(:one),
      schedule:,
      amount: 1,
      price: menu.price,
      discounted_price: menu.price,
      address: companies(:gogrow).address,
      delivery_method: :office,
      notes:,
      selected_options: [
        { group_id: salsa.id, name: "Salsa", values: [ values[:salsa] ] },
        { group_id: relleno.id, name: "Relleno", values: [ values[:relleno] ] }
      ]
    )
  end

  it "le muestra al proveedor lo que el empleado eligió, no todas las opciones del plato" do
    order = order_with(values: { salsa: "Bolognesa", relleno: "Ricota y nuez" })

    sign_in users(:other_provider_user), role: :provider
    visit provider_order_path(order)

    expect(page).to have_content("Salsa")
    expect(page).to have_content("Bolognesa")
    expect(page).to have_content("Relleno")
    expect(page).to have_content("Ricota y nuez")
    # Filetto y Espinaca y queso los ofrece el plato, pero el empleado no los pidió.
    expect(page).to have_no_content("Filetto")
    expect(page).to have_no_content("Espinaca y queso")
  end

  it "le muestra al proveedor las notas que el empleado escribió" do
    order = order_with(values: { salsa: "Filetto", relleno: "Ricota y nuez" }, notes: "Sin sal, por favor")

    sign_in users(:other_provider_user), role: :provider
    visit provider_order_path(order)

    expect(page).to have_content("Sin sal, por favor")
  end

  it "no inventa una personalización para los pedidos hechos antes de esta funcionalidad" do
    order = order_with(values: { salsa: "Filetto", relleno: "Ricota y nuez" })
    # Los pedidos anteriores a la personalización no tienen elección guardada, pero el
    # proveedor tiene que poder confirmarlos igual.
    order.update_column(:selected_options, [])

    sign_in users(:other_provider_user), role: :provider
    visit provider_order_path(order)

    expect(page).to have_content("Salsa")
    expect(page).to have_content("Sin datos")
    expect(order.reload.update(status: :confirmed)).to be(true)
  end

  it "no le muestra a otro proveedor la personalización de un pedido que no es suyo" do
    order = order_with(values: { salsa: "Bolognesa", relleno: "Ricota y nuez" })

    sign_in users(:provider_user), role: :provider
    visit provider_order_path(order)

    expect(page).to have_no_content("Bolognesa")
    expect(page).to have_no_content("Ricota y nuez")
  end
end
