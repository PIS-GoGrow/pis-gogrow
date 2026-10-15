# frozen_string_literal: true

# Historia "Como PROVEEDOR, quiero ser notificado si se cancela una orden que ya
# había sido confirmada para poder gestionar adecuadamente los pedidos a preparar."
#
# TODO(integración): falta implementar el envío real por WhatsApp
# (WhatsappSenderJob tiene el POST a la API comentado, sin token ni teléfono
# configurable) antes de poder testear que el proveedor recibe la cancelación por
# ese canal cuando lo tiene configurado (CA3). Hoy solo se prueba que el envío se
# encola o no, en spec/services/notifier_spec.rb. Historia: IBP-072.

require "rails_helper"

RSpec.describe "Ver la notificación de pedido cancelado", type: :system do
  fixtures :users, :companies, :providers, :consumers, :menus, :menu_option_groups, :schedules, :orders

  let(:title) { "Un pedido fue cancelado" }

  before { page.current_window.resize_to(1400, 1400) }

  def cancel_as_consumer(order)
    sign_in users(:one), role: :consumer
    visit_hydrated order_path(order)
    without_animations
    click_button "Cancelar"
    within("[role=dialog]") { click_button "Cancelar pedido" }
    expect(page).to have_content("Pedido cancelado")
    sign_out
  end

  it "le muestra al proveedor el banner con el empleado, la fecha y el plato, y lo puede cerrar" do
    order = orders(:upcoming_confirmed_future)
    cancel_as_consumer(order)

    sign_in users(:provider_user), role: :provider
    visit_hydrated provider_dashboard_path

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

  it "le muestra un solo aviso por cada cancelación" do
    cancel_as_consumer(orders(:upcoming_confirmed_future))

    sign_in users(:provider_user), role: :provider
    visit provider_dashboard_path

    expect(page).to have_css("[role=alert]", text: title, count: 1)
  end

  it "no le avisa al proveedor si el pedido cancelado todavía estaba pendiente" do
    cancel_as_consumer(orders(:upcoming_pending_future))

    sign_in users(:provider_user), role: :provider
    visit provider_dashboard_path

    expect(page).to have_content("Hola,")
    expect(page).to have_no_content(title)
  end

  # CA1: solo dentro de la ventana permitida. Un pedido confirmado que se entrega
  # hoy ya no se puede cancelar, así que tampoco hay aviso.
  it "no le avisa al proveedor cuando la cancelación está fuera de la ventana permitida" do
    order = orders(:upcoming_pending_today)
    order.update_columns(status: Order.statuses[:confirmed])

    sign_in users(:one), role: :consumer
    visit_hydrated order_path(order)
    expect(page).to have_button("Cancelar", disabled: true)
    sign_out

    sign_in users(:provider_user), role: :provider
    visit provider_dashboard_path
    expect(page).to have_content("Hola,")
    expect(page).to have_no_content(title)
  end

  # Transversal (permisos/privacidad): el aviso es de un proveedor, no de todos.
  it "no le muestra el aviso a otro proveedor" do
    cancel_as_consumer(orders(:upcoming_confirmed_future))

    sign_in users(:other_provider_user), role: :provider
    visit provider_dashboard_path

    expect(page).to have_content("Hola,")
    expect(page).to have_no_content(title)
  end
end
