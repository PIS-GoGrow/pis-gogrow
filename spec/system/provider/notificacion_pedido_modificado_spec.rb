# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Notificación al proveedor cuando el empleado modifica la cantidad del pedido", type: :system do
  fixtures :users, :companies, :providers, :consumers, :menus, :schedules, :orders

  let(:order) { orders(:upcoming_pending_future) }
  let(:consumer_user) { users(:one) }
  let(:provider_user) { users(:provider_user) }
  let(:notification_title) { "Nuevo pedido" }

  before do
    page.current_window.resize_to(1400, 1400)
    Notification::Configuration.find_or_create_by!(key: "provider_orders") do |c|
      c.roles = %w[provider]
    end
    order.notify_received
  end

  def modify_order_as_consumer(order, quantity:, notes: nil)
    sign_in consumer_user, role: :consumer
    delivery = {
      delivery_method: order.delivery_method,
      address: order.address
    }
    order.modify(
      by: consumer_user,
      quantity:,
      notes: notes || order.notes,
      delivery:
    )
    sign_out
  end

  it "actualiza la notificación activa cuando el empleado cambia la cantidad y no crea duplicados" do
    sign_in provider_user, role: :provider
    visit_hydrated provider_dashboard_path

    expect(page).to have_content(notification_title)
    expect(page).to have_content("pidió 1 de")
    expect(page).to have_css("[role=alert]", text: notification_title, count: 1)
    sign_out

    modify_order_as_consumer(order, quantity: 3)

    sign_in provider_user, role: :provider
    visit_hydrated provider_dashboard_path

    expect(page).to have_content(notification_title)
    expect(page).to have_content("pidió 3 de")
    expect(page).to have_css("[role=alert]", text: notification_title, count: 1)
  end

  it "crea una nueva notificación activa si la anterior ya había sido cerrada" do
    sign_in provider_user, role: :provider
    visit_hydrated provider_dashboard_path

    expect(page).to have_content(notification_title)
    click_button "Cerrar notificación"
    expect(page).to have_no_content(notification_title)
    sign_out

    modify_order_as_consumer(order, quantity: 4)

    sign_in provider_user, role: :provider
    visit_hydrated provider_dashboard_path

    expect(page).to have_content(notification_title)
    expect(page).to have_content("pidió 4 de")
    expect(page).to have_css("[role=alert]", text: notification_title, count: 1)
  end

  it "no modifica ni recrea la notificación cuando solo se modifican notas" do
    sign_in provider_user, role: :provider
    visit_hydrated provider_dashboard_path
    expect(page).to have_content(notification_title)
    expect(page).to have_content("pidió 1 de")
    sign_out

    modify_order_as_consumer(order, quantity: 1, notes: "Sin cebolla por favor")

    sign_in provider_user, role: :provider
    visit_hydrated provider_dashboard_path

    expect(page).to have_content(notification_title)
    expect(page).to have_content("pidió 1 de")
    expect(page).to have_css("[role=alert]", text: notification_title, count: 1)
  end
end
