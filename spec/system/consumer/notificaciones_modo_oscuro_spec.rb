# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Notificaciones en modo oscuro", type: :system do
  fixtures :users, :companies, :consumers

  let(:consumer_user) { users(:one) }
  let(:notification_configuration) do
    Notification::Configuration.find_or_create_by!(key: "order_updates") do |c|
      c.roles = %w[consumer]
    end
  end

  before do
    page.current_window.resize_to(1400, 1400)
    Notification.create!(
      notification_configuration:,
      user: consumer_user,
      role: "consumer",
      event: "order_confirmation",
      requires_action: false,
      notifiable: consumer_user,
      title: "Tu pedido fue confirmado",
      description: "Tu pedido fue confirmado por el proveedor."
    )
  end

  it "muestra el ícono con currentColor en modo claro y oscuro, y permite cerrarla en modo oscuro" do
    sign_in consumer_user, role: :consumer
    visit dashboard_path

    # Modo claro
    expect(page).to have_content("Tu pedido fue confirmado")
    expect(page).to have_content("Tu pedido fue confirmado por el proveedor.")
    expect(page).to have_css("[role=alert] svg circle[stroke='currentColor']")
    expect(page).to have_no_css("[role=alert] svg [stroke='#0A0A0A']")

    # Cambiar a modo oscuro en configuración de apariencia
    visit settings_appearance_path
    click_button "Oscuro"
    expect(page).to have_css("html.dark")

    # Volver al inicio y verificar el banner en modo oscuro
    visit dashboard_path
    expect(page).to have_css("html.dark")
    expect(page).to have_content("Tu pedido fue confirmado")
    expect(page).to have_content("Tu pedido fue confirmado por el proveedor.")
    expect(page).to have_css("[role=alert] svg circle[stroke='currentColor']")
    expect(page).to have_no_css("[role=alert] svg [stroke='#0A0A0A']")

    # Cerrar la notificación en modo oscuro
    click_button "Cerrar notificación"
    expect(page).to have_no_content("Tu pedido fue confirmado")

    # Persiste cerrada al recargar
    visit dashboard_path
    expect(page).to have_no_content("Tu pedido fue confirmado")
  end
end
