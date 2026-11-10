# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Buzón de notificaciones en el inicio", type: :system do
  fixtures :users, :companies, :providers, :consumers, :menus, :menu_option_groups, :schedules, :orders

  let(:consumer_user) { users(:one) }
  let(:order) { orders(:upcoming_pending_today) }

  let(:order_config) do
    Notification::Configuration.find_or_create_by!(key: "order_updates") do |c|
      c.roles = %w[consumer]
    end
  end

  let(:payment_config) do
    Notification::Configuration.find_or_create_by!(key: "automatic_payment_reminders") do |c|
      c.roles = %w[consumer]
    end
  end

  let(:debt_config) do
    Notification::Configuration.find_or_create_by!(key: "debt_alerts") do |c|
      c.roles = %w[consumer]
    end
  end

  let!(:dismissable_notif_1) do
    Notification.create!(
      notification_configuration: order_config,
      user: consumer_user,
      role: "consumer",
      event: "order_confirmation",
      requires_action: false,
      notifiable: order,
      title_data: {},
      description_data: { date: "15 de noviembre", provider: "Tu Viandita" }
    )
  end

  let!(:dismissable_notif_2) do
    Notification.create!(
      notification_configuration: payment_config,
      user: consumer_user,
      role: "consumer",
      event: "payment_approved",
      requires_action: false,
      notifiable: consumer_user,
      title_data: {},
      description_data: { provider: "Tu Viandita", month: "octubre 2026" }
    )
  end

  let!(:action_required_notif) do
    Notification.create!(
      notification_configuration: debt_config,
      user: consumer_user,
      role: "consumer",
      event: "debt_threshold_exceeded",
      requires_action: true,
      notifiable: consumer_user,
      title_data: {},
      description_data: { debt: "$2.500", threshold: "$2.000" }
    )
  end

  before do
    page.current_window.resize_to(1400, 1000)
    sign_in consumer_user, role: :consumer
  end

  it "muestra solo notificaciones que requieren acción en banners y lista las cerrables en el buzón" do
    visit dashboard_path
    wait_for_hydration

    # La notificación que requiere acción se muestra como banner en el inicio
    expect(page).to have_content("Tu deuda superó el monto límite")

    # Las cerrables no aparecen directamente en el inicio
    expect(page).to have_no_content("Tu pedido fue confirmado")
    expect(page).to have_no_content("Pago aprobado")

    # La campana muestra el contador de las cerrables (2)
    bell_button = find("button[aria-haspopup=dialog][aria-label='Tenés 2 notificaciones']")
    expect(bell_button).to have_content("2")

    # Abrir el buzón
    open_notifications

    # Ambas notificaciones cerrables están en el buzón
    expect(page).to have_content("Tu pedido fue confirmado")
    expect(page).to have_content("Pago aprobado")

    # Cerrar una de las notificaciones
    within("[role=dialog]") do
      first("button[aria-label='Cerrar notificación']").click
    end

    # La notificación cerrada desaparece y la otra sigue visible
    expect(page).to have_content("Pago aprobado")

    # Cerrar la segunda notificación
    within("[role=dialog]") do
      find("button[aria-label='Cerrar notificación']").click
      expect(page).to have_content("No tenés notificaciones nuevas.")
    end

    # Cerrar el diálogo haciendo clic fuera o recargando la vista
    visit dashboard_path
    wait_for_hydration

    # La campana queda sin badge contador y con label por defecto
    expect(page).to have_css("button[aria-haspopup=dialog][aria-label='Notificaciones']")
    expect(page).to have_no_css("button[aria-haspopup=dialog] span", text: "1")
    expect(page).to have_no_css("button[aria-haspopup=dialog] span", text: "2")

    # Al abrir el buzón vacío, muestra el mensaje correspondiente
    open_notifications
    expect(page).to have_content("No tenés notificaciones nuevas.")
  end

  it "funciona en vista mobile abriendo el sheet inferior" do
    page.current_window.resize_to(375, 667)
    visit dashboard_path
    wait_for_hydration

    # La campana está visible junto al título
    expect(page).to have_css("button[aria-haspopup=dialog][aria-label='Tenés 2 notificaciones']")

    # Abrir el buzón en mobile
    open_notifications
    expect(page).to have_content("Tu pedido fue confirmado")

    # Cerrar notificación en mobile
    within("[role=dialog]") do
      first("button[aria-label='Cerrar notificación']").click
    end

    expect(page).to have_content("Pago aprobado")
  end
end
