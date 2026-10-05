# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Pedidos del consumidor" do
  fixtures :users, :consumers, :companies, :providers, :menus, :schedules, :orders

  before do
    sign_in users(:one), role: :consumer
  end

  it "permite consultar pedidos próximos e historial de los últimos 3 meses" do
    visit orders_path

    expect(page).to have_content("Mis pedidos")
    expect(page).to have_content("Próximos")
    expect(page).to have_content("Historial")

    # Pestaña Próximos
    expect(page).to have_content("Milanesa con papas fritas")

    # Pestaña Historial
    find("[role=tab]", text: "Historial").click
    expect(page).to have_content("Rechazado")
    expect(page).to have_content("Cancelado")
  end

  it "permite filtrar pedidos por proveedor en tiempo real" do
    visit orders_path

    expect(page).to have_content("Proveedores: Todos")

    find("button[aria-label='Filtrar por proveedores']").click
    unless page.has_selector?("[role=dialog]", wait: 2)
      find("button[aria-label='Filtrar por proveedores']").click
    end

    within("[role=dialog]") do
      expect(page).to have_content("Filtrar por proveedores")
      find("label", text: "Provider User").click
      click_button "Aplicar"
    end

    expect(page).to have_content("Proveedores: Provider User")
  end


  it "permite cancelar un pedido desde la lista de órdenes" do
    visit orders_path

    order_card = find("[data-slot=card]", text: "Milanesa con papas fritas", match: :first)
    within(order_card) do
      click_button "Cancelar"
    end

    within("[role=dialog]") do
      expect(page).to have_content("¿Cancelar pedido?")
      click_button "Cancelar pedido"
    end

    expect(page).to have_content("Pedido cancelado")
  end

  it "permite editar un pedido desde la lista de órdenes navegando a la edición" do
    visit orders_path

    order_card = find("[data-slot=card]", text: "Milanesa con papas fritas", match: :first)
    within(order_card) do
      click_link "Editar"
    end

    expect(page).to have_current_path(/edit=1/)
    within("[role=dialog]") do
      expect(page).to have_content("Modificar pedido") 
      fill_in "notes", with: "Sin cebolla por favor"
      click_button "Guardar cambios"
    end

    expect(page).to have_content("Pedido actualizado")
    expect(page).to have_content("Sin cebolla por favor")
  end

  it "permite modificar y cancelar desde la pantalla de detalle de la orden" do
    order = orders(:upcoming_pending_future)

    visit order_path(order)

    # Modificar desde el detalle
    click_button "Editar"
    within("[role=dialog]") do
      fill_in "notes", with: "Con servilletas extras"
      click_button "Guardar cambios"
    end

    expect(page).to have_content("Pedido actualizado")
    expect(page).to have_content("Con servilletas extras")

    # Cancelar desde el detalle
    click_button "Cancelar"
    within("[role=dialog]") do
      click_button "Cancelar pedido"
    end

    expect(page).to have_content("Pedido cancelado")
  end

  it "muestra ambos botones deshabilitados sin los textos de advertencia cuando el pedido está confirmado para hoy" do
    confirmed = orders(:upcoming_pending_today)
    confirmed.update_columns(status: Order.statuses[:confirmed])

    visit order_path(confirmed)

    expect(page).to have_button("Cancelar", disabled: true)
    expect(page).to have_button("Editar", disabled: true)
    expect(page).not_to have_content("Ya está confirmado para hoy, así que no se puede cancelar.")
    expect(page).not_to have_content("El proveedor ya confirmó este pedido, así que no se puede modificar.")
  end




  it "muestra el motivo de rechazo en la vista de detalle de un pedido rechazado" do
    rejected = orders(:history_rejected_future)
    rejected.update_columns(rejection_reason: Order.rejection_reasons[:out_of_stock])

    visit order_path(rejected)

    expect(page).to have_content("Rechazado")
    expect(page).to have_content("Motivo de rechazo")
    expect(page).to have_content("Sin stock disponible")
  end

  it "muestra los detalles personalizados cuando el motivo de rechazo es 'otro'" do
    rejected = orders(:history_rejected_future)
    rejected.update_columns(
      rejection_reason: Order.rejection_reasons[:other],
      rejection_details: "La cocina cerró por corte de agua"
    )

    visit order_path(rejected)

    expect(page).to have_content("Motivo de rechazo")
    expect(page).to have_content("La cocina cerró por corte de agua")
  end
end
