# frozen_string_literal: true

module NotificationHelpers
  BELL = "button[aria-haspopup=dialog][aria-label^='Tenés'], button[aria-haspopup=dialog][aria-label='Notificaciones']"

  # Las notificaciones que se pueden cerrar viven en el buzón de la campana, no en
  # los banners del inicio.
  def open_notifications
    wait_for_hydration
    find(BELL).click
    expect(page).to have_css("[role=dialog]", text: "Notificaciones")
  end
end

RSpec.configure do |config|
  config.include NotificationHelpers, type: :system
end
