# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Pedidos del consumidor" do
  fixtures :users, :consumers, :companies, :providers, :menus, :schedules, :orders

  before do
    sign_in users(:one), role: :consumer
  end

  def open_provider_filter
    expect(page).to have_no_selector("[role=dialog]")
    find("button[aria-label='Filtrar por proveedores']").click
    return if page.has_selector?("[role=dialog]", wait: 2)

    find("button[aria-label='Filtrar por proveedores']").click
    expect(page).to have_selector("[role=dialog]")
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

  it "filtra el historial por proveedor sin conservar el filtro al recargar" do
    filtered_order = orders(:history_pending_past)
    filtered_order.update_columns(
      provider_id: providers(:office_provider).id,
      provider_name: providers(:office_provider).user.name,
      menu_name: "Ensalada de quinoa"
    )
    orders(:upcoming_pending_future).update_columns(
      provider_id: providers(:endulzate).id,
      provider_name: providers(:endulzate).user.name
    )

    visit orders_path
    find("[role=tab]", text: "Historial").click

    expect(page).to have_content("Proveedores: Todos los proveedores")

    open_provider_filter

    within("[role=dialog]") do
      expect(page).to have_content("Filtrar por proveedores")
      expect(page).to have_content("Todos los proveedores")
      expect(page).to have_selector("#dashboard-filter-all[data-state='checked']")
      find("#dashboard-filter-#{providers(:office_provider).id}").click
      click_button "Aplicar"
    end

    expect(page).to have_current_path(orders_path)
    expect(page).to have_content("Proveedores: Office Provider User")
    expect(page).to have_content("Ensalada de quinoa")
    expect(page).not_to have_content("Milanesa con papas fritas")

    open_provider_filter
    within("[role=dialog]") do
      find("#dashboard-filter-#{providers(:endulzate).id}").click
      expect(page).to have_selector("#dashboard-filter-#{providers(:office_provider).id}[data-state='unchecked']")
      expect(page).to have_selector("#dashboard-filter-#{providers(:endulzate).id}[data-state='checked']")
      find("#dashboard-filter-#{providers(:endulzate).id}").click
      expect(page).to have_selector("#dashboard-filter-all[data-state='checked']")
      click_button "Aplicar"
    end

    expect(page).to have_content("Proveedores: Todos los proveedores")
    expect(page).to have_content("Ensalada de quinoa")
    expect(page).to have_content("Milanesa con papas fritas")

    refresh
    find("[role=tab]", text: "Historial").click
    expect(page).to have_content("Proveedores: Todos los proveedores")
    expect(page).to have_content("Ensalada de quinoa")
    expect(page).to have_content("Milanesa con papas fritas")

    open_provider_filter
    within("[role=dialog]") do
      find("#dashboard-filter-#{providers(:office_provider).id}").click
      click_button "Aplicar"
    end

    open_provider_filter
    within("[role=dialog]") do
      find("#dashboard-filter-all").click
      expect(page).to have_selector("#dashboard-filter-all[data-state='checked']")
      click_button "Aplicar"
    end

    expect(page).to have_content("Milanesa con papas fritas")
  end

  it "filtra el historial con varios proveedores sin mezclar pedidos y respetando el orden por fecha de entrega" do
    office = providers(:office_provider)
    endulzate = providers(:endulzate)
    # Sin schedule para que la fecha de entrega la ponga el test y no la fixture.
    {
      history_confirmed_past: [ office, "Ensalada de quinoa", 30 ],
      history_pending_past: [ office, "Tarta de verduras", 2 ],
      history_without_schedule: [ endulzate, "Budín de limón", 10 ]
    }.each do |fixture, (provider, menu_name, days_ago)|
      orders(fixture).update_columns(
        schedule_id: nil,
        delivery_date: Date.current - days_ago,
        provider_id: provider.id,
        provider_name: provider.user.name,
        menu_name: menu_name
      )
    end

    visit orders_path
    find("[role=tab]", text: "Historial").click
    history = find("[role=tabpanel]", text: "Proveedores:")

    open_provider_filter
    within("[role=dialog]") do
      find("#dashboard-filter-#{office.id}").click
      click_button "Aplicar"
    end

    expect(page).to have_content("Proveedores: Office Provider User")
    expect(history).to have_content("Tarta de verduras")
    expect(history).to have_content("Ensalada de quinoa")
    expect(history).to have_no_content("Budín de limón")
    expect(history).to have_no_content("Milanesa con papas fritas")
    expect(history).to have_no_content("No hay pedidos de este proveedor")
    expect(history.text.index("Tarta de verduras")).to be < history.text.index("Ensalada de quinoa")

    open_provider_filter
    within("[role=dialog]") do
      find("#dashboard-filter-all").click
      click_button "Aplicar"
    end

    expect(page).to have_content("Proveedores: Todos los proveedores")
    expect(history).to have_content("Budín de limón")
    expect(history).to have_content("Milanesa con papas fritas")
    positions = [ "Tarta de verduras", "Budín de limón", "Ensalada de quinoa" ].map { |name| history.text.index(name) }
    expect(positions).to eq(positions.sort)
  end

  it "muestra el estado vacío del historial para un proveedor sin pedidos anteriores" do
    selected = providers(:endulzate)
    orders(:upcoming_pending_future).update_columns(provider_id: selected.id, provider_name: selected.user.name)

    visit orders_path
    find("[role=tab]", text: "Historial").click
    open_provider_filter

    within("[role=dialog]") do
      find("#dashboard-filter-#{selected.id}").click
      click_button "Aplicar"
    end

    expect(page).to have_content("No hay pedidos de este proveedor")
    expect(page).to have_content("No tenés pedidos anteriores realizados a este proveedor.")
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
      expect(page).to have_content("Milanesa con papas fritas")
      fill_in "notes", with: "Sin cebolla por favor"
      click_button "Modificar"

      expect(page).to have_content("Pedido modificado")
      click_button "Listo"
    end

    expect(page).to have_current_path(orders_path)
    expect(page).to have_content("Mis pedidos")
    expect(Order.where(notes: "Sin cebolla por favor")).to exist
  end

  it "vuelve a la lista de órdenes al salir de una edición abierta desde ahí" do
    visit orders_path

    within(find("[data-slot=card]", text: "Milanesa con papas fritas", match: :first)) do
      click_link "Editar"
    end

    within("[role=dialog]") do
      click_button "Volver"
    end

    expect(page).to have_current_path(orders_path)
  end

  it "pide un complementario al agregar unidades a un pedido confirmado" do
    confirmed = orders(:upcoming_confirmed_future)

    visit order_path(confirmed)

    click_button "Editar"
    within("[role=dialog]") do
      click_button "Agregar uno"
      click_button "Modificar"

      expect(page).to have_content("¿Agregar más unidades?")
      click_button "Aumentar pedido"

      expect(page).to have_content("Pedido modificado")
      click_button "Listo"
    end

    complementary = confirmed.consumer.orders.order(:id).last
    expect(page).to have_current_path(order_path(complementary))
    expect(page).to have_content("Pendiente")
    expect(confirmed.reload).to have_attributes(status: "confirmed", amount: 2)
    expect(complementary.amount).to eq(1)
  end

  it "cancela y vuelve a pedir un pedido confirmado al cambiarle otros datos" do
    confirmed = orders(:upcoming_confirmed_future)

    visit order_path(confirmed)

    click_button "Editar"
    within("[role=dialog]") do
      fill_in "notes", with: "Sin sal"
      click_button "Modificar"

      expect(page).to have_content("¿Modificar el pedido?")
      click_button "Modificar pedido"

      expect(page).to have_content("Pedido modificado")
      click_button "Listo"
    end

    replacement = confirmed.consumer.orders.order(:id).last
    expect(page).to have_current_path(order_path(replacement))
    expect(page).to have_content("Sin sal")
    expect(confirmed.reload.status).to eq("cancelled")
  end

  it "permite modificar y cancelar desde la pantalla de detalle de la orden" do
    order = orders(:upcoming_pending_future)

    visit order_path(order)

    # Modificar desde el detalle
    click_button "Editar"
    within("[role=dialog]") do
      fill_in "notes", with: "Con servilletas extras"
      click_button "Modificar"

      expect(page).to have_content("Pedido modificado")
      click_button "Listo"
    end

    expect(page).to have_current_path(order_path(order))
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
    expect(page).not_to have_content("Ya está confirmado para hoy, así que no se puede modificar.")
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
