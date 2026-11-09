# frozen_string_literal: true

# Historia "Como EMPLEADO, quiero recibir una notificación cuando mi pedido sea
# confirmado para estar al tanto del estado de mi pedido."
# Que el empleado ve la notificación se cubre en
# spec/system/consumer/ver_notificacion_pedido_confirmado_spec.rb.
#
# TODO(integración): falta implementar el envío por WhatsApp
# (Notification#send_whatsapp está vacío) antes de poder testear que la
# notificación llega por todos los canales habilitados (CA2). Historia:
# notificación de pedido confirmado (rama feature/74).

require "rails_helper"

RSpec.describe "Confirmar un pedido", type: :system do
  fixtures :users, :companies, :providers, :consumers, :menus, :menu_option_groups, :schedules, :orders

  let(:order) { orders(:upcoming_pending_today) }

  before { page.current_window.resize_to(1400, 1400) }

  # CA1: el estado cambia a "Confirmado", y lo ven igual el proveedor y el empleado.
  it "deja el pedido confirmado para el proveedor y para el empleado" do
    sign_in users(:provider_user), role: :provider
    visit provider_orders_path

    within("[data-slot='card']", text: "PED-#{order.id}") do
      click_button "Confirmar"
      expect(page).to have_content("Confirmado")
    end
    expect(order.reload).to be_confirmed

    sign_out
    sign_in users(:one), role: :consumer
    visit order_path(order)

    expect(page).to have_content("Confirmado")
  end
end
