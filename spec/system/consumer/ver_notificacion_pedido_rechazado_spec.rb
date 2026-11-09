# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Ver la notificación de pedido rechazado", type: :system do
  fixtures :users, :companies, :providers, :consumers, :menus, :menu_option_groups, :schedules, :orders

  let(:order) { orders(:upcoming_pending_today) }
  let(:title) { "Tu pedido fue rechazado" }

  before do
    Notification::Configuration.find_or_create_by!(key: "order_updates") do |configuration|
      configuration.roles = %w[consumer]
    end
    page.current_window.resize_to(1400, 1400)
  end

  def reject_order_as_provider
    sign_in users(:provider_user), role: :provider
    visit_hydrated provider_order_path(order)
    without_animations

    click_button "Rechazar"
    expect(page).to have_content("¿Rechazar pedido?")
    find("#reason-out_of_stock").click
    expect(page).to have_button("Rechazar pedido", disabled: false)
    click_button "Rechazar pedido"

    expect(page).to have_content("Pedido rechazado")
    expect(order.reload).to be_rejected
    sign_out
  end

  it "le muestra al empleado el banner de pedido rechazado con el motivo y lo puede cerrar" do
    sign_in users(:one), role: :consumer
    visit_hydrated dashboard_path
    expect(page).to have_content("Hola,")
    expect(page).to have_no_content(title)
    sign_out

    reject_order_as_provider

    sign_in users(:one), role: :consumer
    visit_hydrated dashboard_path

    expect(page).to have_content(title)
    expect(page).to have_no_content("Tu pedido fue cancelado")
    expect(page).to have_content("fue rechazado por #{users(:provider_user).name}")
    expect(page).to have_content("porque no había stock disponible")

    click_button "Cerrar notificación"
    expect(page).to have_no_content(title)

    visit_hydrated dashboard_path
    expect(page).to have_content("Hola,")
    expect(page).to have_no_content(title)
  end

  it "no le muestra el banner a otro empleado" do
    reject_order_as_provider

    sign_in users(:other_consumer_user), role: :consumer
    visit_hydrated dashboard_path

    expect(page).to have_content("Hola,")
    expect(page).to have_no_content(title)
  end
end
