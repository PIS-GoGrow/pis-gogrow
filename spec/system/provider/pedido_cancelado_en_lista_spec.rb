# frozen_string_literal: true

# Historia IBP-072, CA4: la orden aparece cancelada en la lista operativa del
# proveedor y conserva su historial. Es la contracara operativa del aviso: el
# proveedor ve el pedido como cancelado, y queda registrado quién y cuándo lo
# canceló y en qué estado estaba antes.

require "rails_helper"

RSpec.describe "Ver el pedido cancelado en la lista operativa", type: :system do
  fixtures :users, :companies, :providers, :consumers, :menus, :menu_option_groups, :schedules, :orders

  let(:future_day) { Date.current + 3 }

  before { page.current_window.resize_to(1400, 1400) }

  def day_label(date)
    "Día: #{date.strftime('%d/%m')}"
  end

  def cancel_as_consumer(order)
    sign_in users(:one), role: :consumer
    visit_hydrated order_path(order)
    without_animations
    click_button "Cancelar"
    within("[role=dialog]") { click_button "Cancelar pedido" }
    expect(page).to have_content("Pedido cancelado")
    sign_out
  end

  it "lo muestra como cancelado y conserva quién, cuándo y desde qué estado se canceló" do
    order = orders(:upcoming_confirmed_future)
    cancel_as_consumer(order)

    order.reload
    expect(order).to be_cancelled
    expect(order.status_before_cancellation).to eq("confirmed")
    expect(order.cancelled_by).to eq(users(:one))
    expect(order.cancelled_at).to be_present

    sign_in users(:provider_user), role: :provider
    visit_hydrated provider_orders_path
    click_button day_label(future_day)

    within("[data-slot='card']", text: "PED-#{order.id}") do
      expect(page).to have_content("Milanesa con papas fritas")
      expect(page).to have_content("Cancelado")
    end
  end

  # Transversal: el pedido deja de contarse como confirmado en la lista; ya no
  # aparece con el estado que tenía antes de cancelarse.
  it "no lo sigue mostrando como confirmado en la lista" do
    order = orders(:upcoming_pending_future)
    order.update_columns(status: Order.statuses[:confirmed])
    cancel_as_consumer(order)

    sign_in users(:provider_user), role: :provider
    visit_hydrated provider_orders_path
    click_button day_label(future_day)

    within("[data-slot='card']", text: "PED-#{order.id}") do
      expect(page).to have_content("Cancelado")
      expect(page).to have_no_content("Confirmado")
    end
  end
end
