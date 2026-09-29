# frozen_string_literal: true

module OrderDeadlineHelpers
  def configure_order_deadline(time)
    visit provider_operational_settings_path
    expect(page).to have_content("Hasta qué hora recibís pedidos.")

    if page.has_button?("Agregar hora de cierre", wait: 0)
      click_on "Agregar hora de cierre"
      find_by_id("order_deadline").click
      choose_time(time)
      click_on "Guardar cambios"
    else
      find_button("Hora de cierre").click
      choose_time(time)
    end

    expect(page).to have_content("¡Hora de cierre guardada!")
    click_on "Listo"
    expect(page).to have_button("Hora de cierre", text: time)
  end

  def choose_time(time)
    find("[role=option]", exact_text: time).click
  end
end

RSpec.configure do |config|
  config.include OrderDeadlineHelpers, type: :system
end
