# frozen_string_literal: true

require "rails_helper"

# Historia IBP-097: "Como PROVEEDOR, quiero poder gestionar mis órdenes/pedidos
# desde la aplicación MOBILE."
# CA1: ver los pedidos de los consumidores en el celular.
# CA2: aceptar o rechazar esos pedidos desde el celular.
# CA3: recibir en el celular la notificación de un pedido nuevo.
RSpec.describe "Gestión de pedidos del proveedor en el celular", type: :system do
  fixtures :users, :companies, :providers, :consumers, :menus, :menu_option_groups,
           :schedules, :orders

  let(:provider_user) { users(:provider_user) }
  let(:consumer_user) { users(:one) }
  let(:order) { orders(:upcoming_pending_today) }

  # El contenedor de test tarda decenas de segundos en procesar la respuesta
  # de una acción Inertia; con los 30s por defecto la aserción gana antes.
  around do |example|
    Capybara.using_wait_time(90) { example.run }
  end

  before do
    page.current_window.resize_to(375, 812)
    sign_in provider_user, role: :provider
  end

  # CA1: la barra inferior es la entrada a los pedidos en el celular.
  it "llega a los pedidos desde la barra inferior y ve los del día" do
    visit_hydrated provider_dashboard_path
    without_animations

    within("nav[aria-label='Navegación del proveedor']") { click_link "Pedidos" }

    expect(page).to have_current_path(provider_orders_path)
    expect(page).to have_css(
      "button[aria-expanded='true']",
      text: "Día: #{DateFormat.short(Date.current)}"
    )

    within(provider_order_card(order)) do
      expect(page).to have_content("Test User - GoGrow")
      expect(page).to have_content("Milanesa con papas fritas")
      expect(page).to have_content("x1")
      expect(page).to have_content("Por revisar")
      expect(page).to have_content("Enviar a: Julio Herrera y Reissig 565 (Casa)")
      expect(page).to have_button("Confirmar", disabled: false)
      expect(page).to have_button("Rechazar", disabled: false)
    end
  end

  # CA2: confirmar desde la tarjeta, con aviso de resultado y consistencia para
  # el empleado.
  it "confirma el pedido desde la tarjeta y el empleado ve el cambio" do
    visit_hydrated provider_orders_path
    without_animations

    within(provider_order_card(order)) { click_button "Confirmar" }

    expect(page).to have_content("Pedido confirmado")
    expect(page).to have_content("quedó confirmado y Test User recibirá una notificación")
    click_button "Listo"

    within(provider_order_card(order)) do
      expect(page).to have_content("Confirmado")
    end
    expect(order.reload).to be_confirmed

    sign_out
    sign_in consumer_user, role: :consumer
    visit order_path(order)

    expect(page).to have_content("Confirmado")
  end

  # CA2: rechazar con "Otro motivo", incluyendo el detalle escrito por el
  # proveedor, y verificar el mismo resultado desde el empleado.
  it "rechaza el pedido con otro motivo y ambos roles ven el resultado" do
    visit_hydrated provider_orders_path
    without_animations

    within(provider_order_card(order)) { click_button "Rechazar" }

    expect(page).to have_content("¿Rechazar pedido?")
    find("label", text: "Otro motivo").click
    fill_in "rejection-details", with: "  Sin ingredientes para la salsa  ", fill_options: { rapid: false }
    click_button "Rechazar pedido"

    expect(page).to have_content("Pedido rechazado")
    expect(page).to have_content("Test User recibirá una notificación")
    click_button "Listo"

    within(provider_order_card(order)) do
      expect(page).to have_content("Rechazado")
    end

    order.reload
    expect(order).to be_rejected
    expect(order.rejection_reason).to eq("other")
    expect(order.rejection_details).to eq("Sin ingredientes para la salsa")

    within(provider_order_card(order)) { click_link "Test User - GoGrow" }

    expect(page).to have_content("Detalle de pedido")
    expect(page).to have_content("Rechazado")
    expect(page).to have_content("Este pedido no será cobrado")
    expect(page).to have_content("Sin ingredientes para la salsa")

    sign_out
    sign_in consumer_user, role: :consumer
    visit order_path(order)

    expect(page).to have_content("Rechazado")
    expect(page).to have_content("Motivo de rechazo")
    expect(page).to have_content("Sin ingredientes para la salsa")
  end

  # CA2, caso negativo: sin motivo, o con "Otro motivo" y solo espacios, el
  # botón queda deshabilitado y el pedido no cambia.
  it "no permite rechazar sin motivo ni con un detalle en blanco" do
    visit_hydrated provider_orders_path
    without_animations

    within(provider_order_card(order)) { click_button "Rechazar" }

    expect(page).to have_button("Rechazar pedido", disabled: true)

    find("label", text: "Otro motivo").click
    fill_in "rejection-details", with: "   ", fill_options: { rapid: false }

    expect(page).to have_button("Rechazar pedido", disabled: true)

    click_button "Volver"

    expect(page).to have_no_content("¿Rechazar pedido?")
    expect(order.reload).to be_pending
  end

  # CA3: la notificación de un pedido nuevo aparece en el inicio del celular.
  it "recibe en el celular la notificación de un pedido nuevo y puede cerrarla" do
    Notification::Configuration.find_or_create_by!(key: "provider_orders") do |configuration|
      configuration.roles = %w[provider]
    end
    order.notify_received

    visit_hydrated provider_dashboard_path
    without_animations

    expect(page).to have_css("[role=alert]", text: "Nuevo pedido")
    expect(page).to have_content("Test User pidió 1 de Milanesa con papas fritas para el")

    click_button "Cerrar notificación"

    expect(page).to have_no_content("Nuevo pedido")

    visit_hydrated provider_dashboard_path

    expect(page).to have_no_content("Nuevo pedido")
  end

  # Transversal: un rol ajeno no entra por más que escriba la URL.
  it "no deja que un consumidor entre a los pedidos del proveedor" do
    sign_out
    sign_in consumer_user, role: :consumer

    visit provider_orders_path

    expect(page).to have_current_path(dashboard_path)
    expect(page).to have_content("No tenés permiso para acceder a este recurso.")
  end

  # Transversal: sin sesión, al inicio de sesión del proveedor.
  it "manda al inicio de sesión del proveedor cuando no hay sesión" do
    sign_out

    visit provider_orders_path

    expect(page).to have_current_path(provider_sign_in_path)
  end

  # Transversal: dos proveedores de la misma empresa no ven los pedidos ajenos.
  it "muestra la pantalla 404 al abrir el pedido de otro proveedor" do
    other_order = Order.create!(
      consumer: consumers(:other),
      schedule: schedules(:sorrentinos_today),
      status: :pending,
      delivery_method: :office,
      amount: 1,
      price: 320.00,
      discounted_price: 160.00,
      selected_options: selection_for(schedules(:sorrentinos_today).menu)
    )

    visit provider_order_path(other_order)

    expect(page).to have_content("¡Ups! Esta página no existe")
    expect(page).to have_no_content(other_order.menu_name.to_s)
  end
end
