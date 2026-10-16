# frozen_string_literal: true

# Historia "Como EMPLEADO, quiero recibir una notificación cuando mi pedido sea
# confirmado para estar al tanto del estado de mi pedido." La parte de "el
# empleado la ve" (CA2, CA3), con la interfaz de banners en el inicio.

require "rails_helper"

RSpec.describe "Ver la notificación de pedido confirmado", type: :system do
  fixtures :users, :companies, :providers, :consumers, :menus, :menu_option_groups, :schedules, :orders

  let(:order) { orders(:upcoming_pending_today) }
  let(:title) { "Tu pedido fue confirmado" }

  before do
    Notification::Configuration.find_or_create_by!(key: "order_updates") do |configuration|
      configuration.roles = %w[consumer]
    end
    page.current_window.resize_to(1400, 1400)
  end

  def confirm_order_as_provider
    sign_in users(:provider_user), role: :provider
    visit provider_orders_path
    within("[data-slot='card']", text: "PED-#{order.id}") do
      click_button "Confirmar"
      expect(page).to have_content("Confirmado")
    end
    sign_out
  end

  it "le muestra al empleado el banner con la fecha de entrega y el proveedor, y lo puede cerrar" do
    sign_in users(:one), role: :consumer
    visit dashboard_path
    expect(page).to have_content("Hola,")
    expect(page).to have_no_content(title)
    sign_out

    confirm_order_as_provider

    sign_in users(:one), role: :consumer
    visit dashboard_path

    expect(page).to have_content(title)
    expect(page).to have_content(
      "Tu pedido del #{I18n.l(order.schedule.date, format: :short)} fue confirmado por #{users(:provider_user).name}."
    )

    click_button "Cerrar notificación"
    expect(page).to have_no_content(title)

    visit dashboard_path
    expect(page).to have_content("Hola,")
    expect(page).to have_no_content(title)
  end

  it "no le muestra el banner a otro empleado" do
    confirm_order_as_provider

    sign_in users(:other_consumer_user), role: :consumer
    visit dashboard_path

    expect(page).to have_content("Hola,")
    expect(page).to have_no_content(title)
  end
end
