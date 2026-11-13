# frozen_string_literal: true

# Solicitud de cambio SC-007 sobre IBP-057: si el proveedor no responde un pedido
# en la media hora después de su cierre, se rechaza solo, para que el empleado
# sepa que no le va a llegar y pueda pedirle a otro proveedor que todavía no cerró.
# Lo que puede hacer el proveedor dentro y fuera del margen se cubre en
# spec/system/provider/rechazo_automatico_pedidos_spec.rb.

require "rails_helper"

RSpec.describe "Pedido rechazado por falta de respuesta del proveedor", type: :system do
  fixtures :users, :companies, :admins, :providers, :consumers, :menus

  let(:consumer_user) { users(:one) }
  let(:milanesa) { menus(:milanesa) }
  let(:endulzate) { providers(:endulzate) }
  let(:tarta) { endulzate.menus.create!(name: "Tarta de verdura", description: "Con ensalada", price: 280) }
  # Un lunes futuro: el servidor lo toma como "hoy" y el navegador, que no viaja
  # en el tiempo, no lo marca como fecha pasada.
  let(:monday) { Date.current.next_week(:monday) }
  let!(:order) do
    Order.create!(
      consumer: consumers(:one), schedule: milanesa.schedules.create!(date: monday), amount: 1,
      price: milanesa.price, discounted_price: milanesa.price, delivery_method: :office
    )
  end

  around do |example|
    travel_to(at(11, 0)) { example.run }
  end

  before do
    Notification::Configuration.find_or_create_by!(key: "order_updates") do |configuration|
      configuration.roles = %w[consumer]
    end
    providers(:tuviandita).update!(order_deadline: "12:00")
    endulzate.update!(order_deadline: "14:00")
    page.current_window.resize_to(1400, 1400)

    travel_to at(12, 30)
    UnansweredOrdersRejectionJob.perform_now
  end

  def at(hour, min) = Time.zone.local(monday.year, monday.month, monday.day, hour, min)

  # Criterio 4: el empleado se entera por el buzón de notificaciones y lo ve en su historial.
  it "le avisa al empleado y le muestra el pedido rechazado con el motivo" do
    sign_in consumer_user, role: :consumer
    visit_hydrated dashboard_path
    open_notifications

    expect(page).to have_content("Tu pedido fue rechazado")
    expect(page).to have_content("porque no lo confirmó a tiempo")

    visit_hydrated orders_path
    without_animations
    find("button", text: "Historial").click
    card = find("a[href='#{order_path(order)}']").ancestor("[data-slot='card']")
    within(card) { expect(page).to have_content("Rechazado") }

    visit_hydrated order_path(order)
    expect(page).to have_content("Rechazado")
    expect(page).to have_content("Sin respuesta del proveedor")
  end

  # Persistencia: sigue rechazado tras recargar y con una sesión nueva.
  it "sigue mostrando el rechazo tras recargar y volver a entrar" do
    sign_in consumer_user, role: :consumer
    visit_hydrated order_path(order)
    page.refresh
    expect(page).to have_content("Sin respuesta del proveedor")

    sign_out
    sign_in consumer_user, role: :consumer
    visit_hydrated order_path(order)
    expect(page).to have_content("Rechazado")
    expect(page).to have_content("Sin respuesta del proveedor")
  end

  # Criterio 5: la razón del cambio. Rechazado a las 12:30, todavía puede pedirle
  # el mismo día a un proveedor que cierra a las 14:00.
  it "deja pedirle el mismo día a otro proveedor que todavía no cerró" do
    tarta.schedules.create!(date: monday)

    sign_in consumer_user, role: :consumer
    visit_hydrated dashboard_path
    without_animations

    expect(page).to have_button("Agregar #{milanesa.name}", disabled: true)
    click_button "Agregar #{tarta.name}"
    click_button "Agregar"
    click_link "Ver carrito"
    expect(page).to have_content("Tu carrito")
    click_button "Confirmar pedido"
    expect(page).to have_content("¡Pedido recibido!")

    new_order = consumers(:one).orders.where(provider: endulzate).sole
    expect(new_order).to have_attributes(status: "pending", delivery_date: monday, menu_name: tarta.name)
    expect(order.reload).to be_rejected
  end

  # Privacidad entre pares: otro empleado no tiene el aviso en su buzón ni ve el pedido.
  it "no le muestra el rechazo a otro empleado" do
    sign_in users(:other_consumer_user), role: :consumer
    visit_hydrated dashboard_path
    expect(page).to have_content("Hola,")
    open_notifications
    expect(page).to have_no_content("Tu pedido fue rechazado")

    visit order_path(order)
    expect(page).to have_no_content("Sin respuesta del proveedor")
  end

  # Criterio 8: en la auditoría queda como un rechazo hecho por el sistema.
  it "lo registra en la auditoría de RR. HH. como un rechazo del sistema" do
    sign_in users(:admin), role: :admin
    visit_hydrated admin_order_events_path

    row = find("tbody tr", text: "PED-#{order.id}", match: :first)
    within(row) do
      expect(page).to have_content("Sistema")
      expect(page).to have_content("Rechazo")
    end
  end
end
