# frozen_string_literal: true

# Historia "Como PROVEEDOR, quiero ser notificado si se cancela una orden que ya
# había sido confirmada para poder gestionar adecuadamente los pedidos a preparar."

require "rails_helper"

RSpec.describe "Ver la notificación de pedido cancelado", type: :system do
  fixtures :users, :companies, :providers, :consumers, :menus, :menu_option_groups, :schedules, :orders

  let(:title) { "Un pedido fue cancelado" }

  before { page.current_window.resize_to(1400, 1400) }

  def cancel_as_consumer(order)
    sign_in users(:one), role: :consumer
    visit order_path(order)
    click_button "Cancelar"
    within("[role=dialog]") { click_button "Cancelar pedido" }
    expect(page).to have_content("Pedido cancelado")
    sign_out
  end

  it "le muestra al proveedor el banner con el empleado, la fecha y el plato, y lo puede cerrar" do
    order = orders(:upcoming_confirmed_future)
    cancel_as_consumer(order)

    sign_in users(:provider_user), role: :provider
    visit provider_dashboard_path

    expect(page).to have_content(title)
    expect(page).to have_content(
      "El pedido de #{users(:one).name} del #{order.schedule.date.strftime("%d/%m")} de #{order.menu_name} fue cancelado."
    )

    click_button "Cerrar notificación"
    expect(page).to have_no_content(title)

    visit provider_dashboard_path
    expect(page).to have_content("Hola,")
    expect(page).to have_no_content(title)
  end

  it "no le avisa al proveedor si el pedido cancelado todavía estaba pendiente" do
    cancel_as_consumer(orders(:upcoming_pending_future))

    sign_in users(:provider_user), role: :provider
    visit provider_dashboard_path

    expect(page).to have_content("Hola,")
    expect(page).to have_no_content(title)
  end
end
