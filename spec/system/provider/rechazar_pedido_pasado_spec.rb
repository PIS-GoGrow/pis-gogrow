# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rechazo de pedidos pasados por el proveedor", type: :system do
  fixtures :users, :companies, :providers, :consumers, :menus, :menu_option_groups, :schedules, :orders

  let(:provider_user) { users(:provider_user) }
  let(:confirmed_past_order) { orders(:history_confirmed_past) }
  let(:pending_past_order) { orders(:history_pending_past) }
  let(:confirmed_future_order) { orders(:upcoming_confirmed_future) }

  before do
    page.current_window.resize_to(1400, 1400)
    sign_in provider_user, role: :provider
  end

  it "muestra deshabilitados los botones de acción para un pedido confirmado pasado en el historial" do
    visit provider_orders_path
    without_animations

    click_on "Historial"

    within("[data-slot='card']", text: "PED-#{confirmed_past_order.id}") do
      expect(page).to have_button("Rechazar", disabled: true)
      expect(page).to have_button("Confirmar", disabled: true)
    end

    within("[data-slot='card']", text: "PED-#{pending_past_order.id}") do
      expect(page).to have_button("Rechazar", disabled: false)
    end
  end

  it "muestra deshabilitado el botón de rechazar en el detalle de un pedido confirmado pasado" do
    visit provider_order_path(confirmed_past_order)
    without_animations

    expect(page).to have_content("Detalle de pedido")
    expect(page).to have_button("Rechazar", disabled: true)
    expect(page).to have_button("Confirmar", disabled: true)
  end

  it "mantiene habilitado el rechazo para pedidos confirmados futuros" do
    visit provider_order_path(confirmed_future_order)
    without_animations

    expect(page).to have_content("Detalle de pedido")
    expect(page).to have_button("Rechazar", disabled: false)

    click_button "Rechazar"
    expect(page).to have_content("¿Rechazar el pedido PED-#{confirmed_future_order.id}?")
  end
end
